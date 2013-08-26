module MemoryManager.PageAllocator;

import MemoryManager.Memory;

class PageAllocator {
static:
	private __gshared VirtualAddress curPos;
	private __gshared bool initialize;
	
	@property void IsInit(bool v) { initialize = v; }
	@property bool IsInit() { return initialize; }


	void Init() {
		curPos = cast(VirtualAddress)((Memory.Length & ~0xFFFUL) + 0x1000) - Memory.Length;
		initialize = false;
	}
	
	VirtualAddress AllocPage(uint count = 1) {
		if (!count)
			count = 1;
		
		ulong ret;
		if (!initialize) {
			ret = cast(ulong)Memory.VirtualStart + Memory.Length + cast(ulong)curPos;
			curPos += 0x1000 * count;
		} else
			ret = cast(ulong)Memory.KernelHeap.Alloc(0x1000 * count);
		
		return cast(VirtualAddress)ret;
	}
}
