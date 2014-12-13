﻿module ObjectManager.DeviceManager;

import VFSManager;
import Architecture;


struct InterruptStack {
align(1):
	ulong R15, R14, R13, R12, R11, R10, R9, R8;
	ulong RBP, RDI, RSI, RDX, RCX, RBX, RAX;
	ulong IntNumber, ErrorCode;
	ulong RIP, CS, Flags, RSP, SS;
}

enum DeviceType {
	Null,
	Misc,
	Terminal,
	Video,
	Audio,
	Disk,
	Input,
	Network,
	Filesystem
}

enum DeviceCommonCall {
	// Return DeviceType
	Type,

	// Return unique identifier for each method
	// eg. "com.trinix.VFSManager.FSNode"
	Identifier,

	// Return 8-digits (2 major, 2 minor, 4 patch) version 
	Version,

	// Return array of found lookups
	Lookup,

	// Translate unique identifier of each call to his ID
	Translate
}

abstract final class DeviceManager {
	private __gshared void function(ref InterruptStack stack) _handlers[48];
	__gshared DirectoryNode DevFS;

	static void RequestIRQ(void function(ref InterruptStack) handle, int intNumber) {
		if (intNumber < 16)
			_handlers[intNumber + 32] = handle;
	}

	static void RequestISR(void function(ref InterruptStack) handle, int intNumber) {
		if (intNumber < 32)
			_handlers[intNumber] = handle;
	}

	static void Handler(ref InterruptStack stack) {
		if (stack.IntNumber < 48) {
			if (_handlers[stack.IntNumber] !is null)
				_handlers[stack.IntNumber](stack);
		}
	}

	static void EOI(int irqNumber) {
		if (irqNumber >= 8)
			Port.Write!byte(0xA0, 0x20);
		
		Port.Write!byte(0x20, 0x20);
	}
}