﻿/**
 * Copyright (c) 2014 Trinix Foundation. All rights reserved.
 * 
 * This file is part of Trinix Operating System and is released under Trinix 
 * Public Source Licence Version 0.1 (the 'Licence'). You may not use this file
 * except in compliance with the License. The rights granted to you under the
 * License may not be used to create, or enable the creation or redistribution
 * of, unlawful or unlicensed copies of an Trinix operating system, or to
 * circumvent, violate, or enable the circumvention or violation of, any terms
 * of an Trinix operating system software license agreement.
 * 
 * You may obtain a copy of the License at
 * http://pastebin.com/raw.php?i=ADVe2Pc7 and read it before using this file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY 
 * KIND, either express or implied. See the License for the specific language
 * governing permissions and limitations under the License.
 * 
 * Contributors:
 *      Matsumoto Satoshi <satoshi@gshost.eu>
 */

module MemoryManager.Heap;

import Core;
import Library;
import MemoryManager;


final class Heap {
	private enum MAGIC = 0xDEADC0DE;
	enum MIN_SIZE      = 0x200000;

	private ulong _start;
	private ulong _end;
	private ulong _free;

	private Index _index;
	private SpinLock _spinLock;

	this(ulong offset, long size, long indexSize) {
		_spinLock = new SpinLock();
		_start    = offset + indexSize;
		_end      = offset + size;
		_free     = _end - _start;

		Header* header = cast(Header *)_start;
		header.Size    = _free;
		header.Magic   = MAGIC;
		header.IsHole  = true;

		Footer* footer = cast(Footer *)_end - Footer.sizeof;
		footer.Head    = header;
        footer.Magic   = MAGIC;

		_index.Data = cast(Header **)offset;
		InsertIntoIndex(header);
	}

	~this() {
		delete _spinLock;
	}

	v_addr Alloc(long size, bool expandable = true) {
		_spinLock.WaitOne();
		scope(exit) _spinLock.Release();

		long newSize = size + Header.sizeof + Footer.sizeof;
		long i;
		for (; i < _index.Size && _index.Data[i].Size < newSize; i++) {}

		if (i == _index.Size) {
			if (expandable) {
				Expand((size + 0xFFF) & 0xFFFFFFFFFFFFF000);
				return Alloc(size, false);
			} else
				assert(false);
		}

		Header* header = _index.Data[i];
		Footer* footer = cast(Footer *)(cast(ulong)header + header.Size - Footer.sizeof);
		header.IsHole = false;
		RemoveFromIndex(header);

		if (header.Size > (newSize + Header.sizeof + Footer.sizeof)) {
			Footer* newFooter = cast(Footer *)(cast(ulong)header + newSize - Footer.sizeof);
			newFooter.Head    = header;
            newFooter.Magic   = MAGIC;

			Header* newHeader = cast(Header *)(cast(ulong)header + newSize);
			newHeader.IsHole  = true;
            newHeader.Magic   = MAGIC;
			newHeader.Size    = cast(long)footer - cast(long)newHeader + Footer.sizeof;

			header.Size  = newSize;
			footer.Head  = newHeader;
            footer.Magic = MAGIC;

			InsertIntoIndex(newHeader);
		}

		_free -= header.Size;
		return cast(ulong)header + Header.sizeof;
	}

	void Free(v_addr ptr) {
		if (!ptr)
			return;

		Header* header = cast(Header *)(cast(ulong)ptr - Header.sizeof);
        if (header.Magic != MAGIC)
			return;

		Footer* footer = cast(Footer *)(cast(ulong)header + header.Size - Footer.sizeof);
        if (footer.Magic != MAGIC)
			return;

		_spinLock.WaitOne();
		scope(exit) _spinLock.Release();

		_free += header.Size;
		Footer* prevFooter = cast(Footer *)(cast(ulong)header - Footer.sizeof);
        if (prevFooter.Magic == MAGIC && prevFooter.Head.IsHole) {
			header = prevFooter.Head;
			RemoveFromIndex(header);

			footer.Head = header;
			header.Size = cast(ulong)footer - cast(ulong)header + Footer.sizeof;
		}

		Header* nextHeader = cast(Header *)(cast(ulong)footer - Footer.sizeof);
        if (nextHeader.Magic == MAGIC && nextHeader.IsHole) {
			RemoveFromIndex(nextHeader);

			footer = cast(Footer *)(cast(ulong)footer + nextHeader.Size);
			footer.Head = header;
			header.Size = cast(ulong)footer - cast(ulong)header + Footer.sizeof;
		}

		header.IsHole = true;
		InsertIntoIndex(header);

		if (cast(ulong)footer == cast(ulong)_end - Footer.sizeof && header.Size >= 0x2000 && cast(ulong)_end - _start > MIN_SIZE)
			Contract();
	}

	private void Expand(size_t quantity) {
		if (quantity & 0xFFF)
			quantity = (quantity & ~0xFFFUL) + 0x1000;

		ulong newEnd = _end + quantity;

		Footer* lastFooter = cast(Footer *)(cast(ulong)_end - Footer.sizeof);
		Header* lastHeader = lastFooter.Head;

		if (lastHeader.IsHole) {
			RemoveFromIndex(lastHeader);
			lastHeader.Size += quantity;

			lastFooter       = cast(Footer *)(cast(ulong)newEnd - Footer.sizeof);
            lastFooter.Magic = MAGIC;
			lastFooter.Head  = lastHeader;

			InsertIntoIndex(lastHeader);
		} else {
			lastHeader = cast(Header *)_end;
			lastFooter = cast(Footer *)(cast(ulong)newEnd - Footer.sizeof);

			lastHeader.IsHole = true;
            lastHeader.Magic  = MAGIC;
			lastHeader.Size   = quantity;

            lastFooter.Magic = MAGIC;
			lastFooter.Head  = lastHeader;

			InsertIntoIndex(lastHeader);
		}

		_end = newEnd;
		_free += quantity;
	}

	private void Contract() {
		Footer* lastFooter = cast(Footer *)(cast(ulong)_end - Footer.sizeof);
		Header *lastHeader = lastFooter.Head;

		if (!lastHeader.IsHole)
			return;

		ulong quantity;
		while (_end - _start - quantity > MIN_SIZE && lastHeader.Size - quantity > 0x1000)
			quantity += 0x1000;

		if (!quantity)
			return;

		ulong newEnd = _end - quantity;
		_free -= quantity;

		RemoveFromIndex(lastHeader);
		lastHeader.Size -= quantity;
		lastFooter       = cast(Footer *)(cast(ulong)lastFooter - quantity);
        lastFooter.Magic = MAGIC;
		lastFooter.Head  = lastHeader;

		_end = newEnd;
	}

	private void RemoveFromIndex(long index) {
		_index.Size--;

		while(index < _index.Size)
			_index.Data[index] = _index.Data[++index];
	}

	private void RemoveFromIndex(Header* header) {
		long index = FindIndexEntry(header);

		if (index != -1)
			RemoveFromIndex(index);
	}

	private long FindIndexEntry(Header* header) {
		foreach (i; 0 .. _index.Size)
			if (_index.Data[i] == header)
				return i;

		return -1;
	}

	private void InsertIntoIndex(Header* header) {
		if ((_index.Size * (Header *).sizeof + cast(ulong)_index.Data) >= _start)
			return;

		long i;
		for (; i < _index.Size && _index.Data[i].Size < header.Size; i++)
			if (_index.Data[i] == header)
				return;


		if (i == _index.Size)
			_index.Data[_index.Size++] = header;
		else {
			long pos = i;
			i = _index.Size;

			while (i > pos)
				_index.Data[i] = _index.Data[--i];

			_index.Size++;
			_index.Data[pos] = header;
		}
	}

	static ulong CalculateIndexSize(ulong size) {
		return (size / 0x1000) * 64 + 0x1000;
	}

	private struct Header {
		uint Magic;
		bool IsHole;
		ulong Size;
	}
	
	private struct Footer {
		uint Magic;
		Header* Head;
	}
	
	private struct Index {
		Header** Data;
		long Size;
	}
}