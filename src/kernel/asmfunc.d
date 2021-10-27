extern(C):

void IoOut32(ushort addr, uint data);
uint IoIn32(ushort addr);
ushort GetCS();
void LoadIDT(ushort limit, ulong offset);
void LoadGDT(ushort limit, ulong offset);
void SetCSSS(ushort cs, ushort ss);
void SetDSAll(ushort value);
//ulong GetCR0();
//void SetCR0(ulong value);
//ulong GetCR2();
void SetCR3(ulong value);
//ulong GetCR3();
//void SwitchContext(void* next_ctx, void* current_ctx);
//void RestoreContext(void* ctx);
//int CallApp(int argc, char** argv, ushort ss, ulong rip, ulong rsp, ulong* os_stack_ptr);
//void IntHandlerLAPICTimer();
//void LoadTR(ushort sel);
//void WriteMSR(uint msr, ulong value);
//void SyscallEntry(void);
//void ExitApp(ulong rsp, int32_t ret_val);
//void InvalidateTLB(ulong addr);
