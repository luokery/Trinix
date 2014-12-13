﻿module Core.Main;

import Core;
import VFSManager;
import TaskManager;
import Architecture;
import MemoryManager;
import ObjectManager;
import SyscallManager;

//Log dorobit... problem je v tom ze ak si vymknem log v processe tak pocas interruptu ho nemozem pouzit...
//v PhysicalMEmory by to chcelo nahrat regiony z multibootu a potom podla nich vytvorit bitmapu

/*
dokoncit VFS., co tam este chyba?... file..., syscally, static cally, acl,...
Dokoncit write/create/remove - spravit Ext2 driver!!!!

Multitasking a synchronizacne prvky, asi rwlock ci jak
eventy, jake??

syscally
kontrolu parametrov pri syscalloch
ACLka do syscallov?

najprv skocit do arch zavislej casti kodu, tj. Arch/xxx/Main.d a az odtial potom preskocit sem...

debugovat Heap... Obcas to pada na expande...

spravit to iste jak je pre VFS.AddDriver ci co ale pre Node zariadenia.
Aby sa z modulu dali pridat veci ako je pipe, pty, vty, atd...

V IDT je nejaky problem s RAX registrom...

documentation, documentation, documentation, ...
*/

/* MemoryMap:
	0xFFFFFFFFE0000000 - mapovane regiony
*/
extern(C) extern const int giBuildNumber;

extern(C) void KernelMain(uint magic, void* info) {
	Log.Initialize();
	Log.Install();

	Log.WriteJSON("{");
	Log.WriteJSON("name", "Trinix");
	Log.WriteJSON("version", "0.0.1 Beta");
	Log.Base = 10;
	Log.WriteJSON("build", cast(int)giBuildNumber);
	Log.Base = 16;

	Log.WriteJSON("architecture", "[");
	Arch.Main(magic, info);
	Log.WriteJSON("]");

	Log.WriteJSON("memory_manager", "[");
	Log.WriteJSON("{");
	Log.WriteJSON("name", "PhysicalMemory");
	Log.WriteJSON("type", "Initialize");
	Log.WriteJSON("value", PhysicalMemory.Initialize());
	Log.WriteJSON("}");

	Log.WriteJSON("{");
	Log.WriteJSON("name", "PhysicalMemory");
	Log.WriteJSON("type", "Install");
	Log.WriteJSON("value", PhysicalMemory.Install());
	Log.WriteJSON("}");

	Log.WriteJSON("{");
	Log.WriteJSON("name", "VirtualMemory");
	Log.WriteJSON("type", "Initialize");
	Log.WriteJSON("value", VirtualMemory.Initialize());
	Log.WriteJSON("}");

	Log.WriteJSON("{");
	Log.WriteJSON("name", "VirtualMemory");
	Log.WriteJSON("type", "Install");
	Log.WriteJSON("value", VirtualMemory.Install());
	Log.WriteJSON("}");
	Log.WriteJSON("]");

	Log.WriteJSON("syscall_manager", "[");
	Log.WriteJSON("{");
	Log.WriteJSON("name", "ResourceManager");
	Log.WriteJSON("type", "Initialize");
	Log.WriteJSON("value", ResourceManager.Initialize());
	Log.WriteJSON("}");

	Log.WriteJSON("{");
	Log.WriteJSON("name", "SyscallHandler");
	Log.WriteJSON("type", "Initialize");
	Log.WriteJSON("value", SyscallHandler.Initialize());
	Log.WriteJSON("}");
	Log.WriteJSON("]");

	Log.WriteJSON("task_manager", "[");
	Log.WriteJSON("{");
	Log.WriteJSON("name", "Task");
	Log.WriteJSON("type", "Initialize");
	Log.WriteJSON("value", Task.Initialize());
	Log.WriteJSON("}");
	Log.WriteJSON("]");

	Log.WriteJSON("vfs_manager", "[");
	Log.WriteJSON("{");
	Log.WriteJSON("name", "VFS");
	Log.WriteJSON("type", "Initialize");
	Log.WriteJSON("value", VFS.Initialize());
	Log.WriteJSON("type", "Install");
	Log.WriteJSON("value", VFS.Install());
	Log.WriteJSON("}");
	Log.WriteJSON("]");

	// Remap PIC...
	Port.Write!byte(0x20, 0x11);
	Port.Write!byte(0xA0, 0x11);
	Port.Write!byte(0x21, 0x20);
	Port.Write!byte(0xA1, 0x28);
	Port.Write!byte(0x21, 0x04);
	Port.Write!byte(0xA1, 0x02);
	Port.Write!byte(0x21, 0x01);
	Port.Write!byte(0xA1, 0x01);
	Port.Write!byte(0x21, 0x00);
	Port.Write!byte(0xA1, 0x00);

	Time.Initialize();
	Time.Install();

	Log.WriteJSON("}");

	ModuleManager.Initialize();
	ModuleManager.LoadBuiltins();

	//mixin(import("../../../Makefile"));


	VFS.Mount(new DirectoryNode(VFS.Root, FSNode.NewAttributes("ext2")), cast(Partition)VFS.Find("/System/Devices/disk0s1"), "ext2");
	VFS.PrintTree(VFS.Root);

	Log.WriteLine("test: ", VFS.Root.Identifier);


	//Thread thr = new Thread(Task.CurrentThread);
	//thr.Start(&testfce, null);
	//thr.AddActive();

	//Task.CurrentThread.WaitEvents(ThreadEvent.DeadChild);


	Log.WriteLine("Running.....", Time.Uptime);

	while (true) {
		//Log.WriteLine("Running.....", Time.Uptime);
	}

/+	foreach (tmp; Multiboot.Modules[0 .. Multiboot.ModulesCount]) {
		char* str = &tmp.String;
		Log.WriteJSON("start", tmp.ModStart);
		Log.WriteJSON("end", tmp.ModEnd);
		Log.WriteJSON("cmd", cast(string)str[0 .. tmp.Size - 17]);

		import Library;
	/*	auto elf = Elf.Load(cast(void *)(cast(ulong)LinkerScript.KernelBase | cast(ulong)tmp.ModStart), "/System/Modules/kokot.html");
		if (elf)
			elf.Relocate(null);*/
	}+/

//	Log.WriteLine("Bye");
}

void testfce() {
	//for (int i = 0; i < 0x100; i++) {
	while (true) {
		/*asm {
			//"mov R8, 0x741";
			"mov R9, 2";
			"syscall";// : : "a"(123), "b"(0x4562), "d"(0xABCD), "D"(0x852), "S"(0x963);
		}*/
		//Handle.StaticCall(1);
		//Log.WriteLine("pica", Time.Now);
		//for (int j = 0; j < 0x100_000_00; j++) {}
	}

	//while (true) {}
	//dorobit Exit thready
}