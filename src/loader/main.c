#include <Uefi.h>
#include <Library/UefiLib.h>
#include <Library/UefiBootServicesTableLib.h>
#include <Library/UefiRuntimeServicesTableLib.h>
#include <Library/PrintLib.h>
#include <Library/MemoryAllocationLib.h>
#include <Library/BaseMemoryLib.h>
#include <Protocol/LoadedImage.h>
#include <Protocol/SimpleFileSystem.h>
#include <Protocol/DiskIo2.h>
#include <Protocol/BlockIo.h>
#include <Guid/FileInfo.h>
// なんか大量にincludeしてるけどよくわからん
// そのうち確認する

#include "elf.hpp"
#include "memmap.h"
#include "fb_conf.h"

void Halt(){
  while(1) __asm__("hlt");
}

EFI_STATUS GetMemMap(struct MemMap* map){
  if(map->buf==NULL)
    return EFI_BUFFER_TOO_SMALL;

  map->map_s = map->buf_s;
  return gBS->GetMemoryMap(
      &map->map_s,
      (EFI_MEMORY_DESCRIPTOR*)map->buf,
      &map->map_key,
      &map->desc_s,
      &map->desc_ver);
}

EFI_STATUS OpenRootDir(EFI_HANDLE image_handle,EFI_FILE_PROTOCOL** root) {
  EFI_STATUS status;
  EFI_LOADED_IMAGE_PROTOCOL* loaded_image;
  EFI_SIMPLE_FILE_SYSTEM_PROTOCOL* fs;

  status = gBS->OpenProtocol(
      image_handle,
      &gEfiLoadedImageProtocolGuid,
      (VOID**)&loaded_image,
      image_handle,
      NULL,
      EFI_OPEN_PROTOCOL_BY_HANDLE_PROTOCOL);
  if(EFI_ERROR(status))return status;

  status = gBS->OpenProtocol(
      loaded_image->DeviceHandle,
      &gEfiSimpleFileSystemProtocolGuid,
      (VOID**)&fs,
      image_handle,
      NULL,
      EFI_OPEN_PROTOCOL_BY_HANDLE_PROTOCOL);
  if(EFI_ERROR(status))return status;

  return fs->OpenVolume(fs,root);
}

EFI_STATUS OpenGOP(EFI_HANDLE image_handle,EFI_GRAPHICS_OUTPUT_PROTOCOL** gop) {
  EFI_STATUS status;
  UINTN num_gop_handles = 0;
  EFI_HANDLE* gop_handles = NULL;

  status = gBS->LocateHandleBuffer(
      ByProtocol,
      &gEfiGraphicsOutputProtocolGuid,
      NULL,
      &num_gop_handles,
      &gop_handles);
  if(EFI_ERROR(status))return status;

  status = gBS->OpenProtocol(
      gop_handles[0],
      &gEfiGraphicsOutputProtocolGuid,
      (VOID**)gop,
      image_handle,
      NULL,
      EFI_OPEN_PROTOCOL_BY_HANDLE_PROTOCOL);
  if(EFI_ERROR(status))return status;

  FreePool(gop_handles);

  return EFI_SUCCESS;
}

EFI_STATUS EFIAPI UefiMain(
    EFI_HANDLE image_handle,
    EFI_SYSTEM_TABLE *system_table){
  EFI_STATUS status;

  Print(L"\nHello.\n\n");

  // メモリマップ

  CHAR8 memmap_buf[4096 * 4];
  struct MemMap memmap = {sizeof(memmap_buf),memmap_buf,0,0,0,0};
  status = GetMemMap(&memmap);
  if(EFI_ERROR(status)){
    Print(L"[ !! ] failed to get mem map: %r\n",status);
    Halt();
  }
  Print(L"[ OK ] memmap loaded\n");

  // 画面表示の準備

  EFI_GRAPHICS_OUTPUT_PROTOCOL* gop;
  OpenGOP(image_handle,&gop);
  struct FBConf fbconf = {
    (UINT8*)gop->Mode->FrameBufferBase,
    gop->Mode->Info->PixelsPerScanLine,
    gop->Mode->Info->HorizontalResolution,
    gop->Mode->Info->VerticalResolution,
    0
  };
  switch(gop->Mode->Info->PixelFormat){
    case PixelRedGreenBlueReserved8BitPerColor:
      fbconf.pixel_fmt = kPixelRGB;
      break;
    case PixelBlueGreenRedReserved8BitPerColor:
      fbconf.pixel_fmt = kPixelBGR;
      break;
    default:
      Print(L"[ !! ] unimplemented pixel format: %d\n",gop->Mode->Info->PixelFormat);
      Halt();
  }
  Print(L"[ OK ] resolution: %ux%u\n",fbconf.res_horiz,fbconf.res_vert);

  // カーネルファイルのロード

  EFI_FILE_PROTOCOL* root_dir;
  status = OpenRootDir(image_handle,&root_dir);
  if(EFI_ERROR(status)){
    Print(L"[ !! ] failed to open root directory: %r\n",status);
    Halt();
  }

  EFI_FILE_PROTOCOL* kernel_file;
  status = root_dir->Open(
      root_dir,&kernel_file,L"\\kernel.elf",
      EFI_FILE_MODE_READ,0);
  if(EFI_ERROR(status)){
    Print(L"[ !! ] failed to open file '\\kernel.elf': %r\n", status);
    Halt();
  }

  UINTN kernel_file_info_s = sizeof(EFI_FILE_INFO)+sizeof(CHAR16)*12; // L"\\kernel.elf"分
  UINT8 kernel_file_info_buf[kernel_file_info_s];
  status = kernel_file->GetInfo(
      kernel_file, &gEfiFileInfoGuid,
      &kernel_file_info_s,kernel_file_info_buf);
  if(EFI_ERROR(status)){
    Print(L"[ !! ] failed to get kernel file information: %r\n", status);
    Halt();
  }
  EFI_FILE_INFO* kernel_file_info = (EFI_FILE_INFO*)kernel_file_info_buf;
  UINTN kernel_file_s = kernel_file_info->FileSize;

  // カーネルのロード

  // ファイルのロード
  VOID* kernel_tmp_buf;
  status = gBS->AllocatePool(EfiLoaderData,kernel_file_s,&kernel_tmp_buf);
  if(EFI_ERROR(status)){
    Print(L"[ !! ] failed to allocate pool: %r\n", status);
    Halt();
  }
  status = kernel_file->Read(kernel_file,&kernel_file_s,kernel_tmp_buf);
  if(EFI_ERROR(status)){
    Print(L"[ !! ] failed to read kernel file: %r\n", status);
    Halt();
  }

  Elf64_Ehdr* kernel_ehdr = (Elf64_Ehdr*)kernel_tmp_buf;
  Elf64_Phdr* kernel_phdr = (Elf64_Phdr*)((UINT64)kernel_ehdr+kernel_ehdr->e_phoff);

  // 範囲/サイズを計算，メモリを確保，そしてコピー
  UINT64 kernel_head_addr = MAX_UINT64,
         kernel_tail_addr = 0;

  for(Elf64_Half i = 0;i < kernel_ehdr->e_phnum;i++)
    if(kernel_phdr[i].p_type==PT_LOAD){
      kernel_head_addr = MIN(kernel_head_addr,kernel_phdr[i].p_vaddr);
      kernel_tail_addr = MAX(kernel_tail_addr,kernel_phdr[i].p_vaddr+kernel_phdr[i].p_memsz);
    }
  UINTN kernel_mem_pages_n = (kernel_tail_addr-kernel_head_addr+0xfff)/0x1000;
  status = gBS->AllocatePages(AllocateAddress,EfiLoaderData,kernel_mem_pages_n,&kernel_head_addr);
  if(EFI_ERROR(status)){
    Print(L"[ !! ] failed to allocate pages: %r\n",status);
    Halt();
  }
  for(Elf64_Half i = 0;i < kernel_ehdr->e_phnum;i++)
    if(kernel_phdr[i].p_type==PT_LOAD){
      UINT64 segm_in_file = (UINT64)kernel_ehdr + kernel_phdr[i].p_offset;
      UINTN remain_bytes = kernel_phdr[i].p_memsz-kernel_phdr[i].p_filesz;
      CopyMem((VOID*)kernel_phdr[i].p_vaddr,(VOID*)segm_in_file,kernel_phdr[i].p_filesz);
      SetMem((VOID*)(kernel_phdr[i].p_vaddr+kernel_phdr[i].p_filesz),remain_bytes,0);
        // SetMem: メモリで余ったとこを0で埋める
    }
  Print(L"[ OK ] kernel loaded: 0x%0lx - 0x%0lx (total %u pages)\n",
        kernel_head_addr,
        kernel_tail_addr,
        kernel_mem_pages_n);

  // ファイルの開放
  status = gBS->FreePool(kernel_tmp_buf);
  if(EFI_ERROR(status)){
    Print(L"[ !! ] failed to free pool of kernel file: %r\n",status);
    Halt();
  }

  // カーネルを実行

  status = gBS->ExitBootServices(image_handle,memmap.map_key);
  if(EFI_ERROR(status)){
    status = GetMemMap(&memmap); // memmap.map_keyの更新
    if(EFI_ERROR(status)){
      Print(L"[ !! ] failed to get mem map: %r\n",status);
      Halt();
    }
    status = gBS->ExitBootServices(image_handle,memmap.map_key);
    if(EFI_ERROR(status)){
      Print(L"[ !! ] failed to exit boot service: %r\n",status);
      Halt();
    }
  }

  typedef void EntryPoint(const struct FBConf*
                          const struct MemMap*);

  UINT64 entry_addr = *(UINT64*)(kernel_head_addr+24);
  EntryPoint* entry_point = (EntryPoint*)entry_addr;
  entry_point(&fbconf, &memmap);

  Halt();
  return EFI_SUCCESS;
}
