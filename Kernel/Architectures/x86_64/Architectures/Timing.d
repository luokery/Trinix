module Architectures.Timing;

import Devices.DeviceProto;


struct Time {
	uint Seconds;
	uint Minutes;
	uint Hours;


	/*void opSubAssign(Time b) {
		ulong total = InSeconds();
		ulong total_b = b.InSeconds();
		total -= total_b;

		Seconds = total % 60;
		total /= 60;
		Minutes = total % 60;
		total /= 60;
		Hours = cast(uint)total;
	}*/

	int opCmp(Time t) {
		return cast(uint)(InSeconds() - t.InSeconds());
	}

	ulong InSeconds() {
		return cast(ulong)Seconds + (cast(ulong)Minutes * 60L) + (cast(ulong)Hours * 60L * 60L);
	}
}

struct Date {
	uint Day;
	uint Month;
	uint Year;
}


class Timing {
static:
	Date CurrentDate() {
		ubyte day, month, year;

		asm {
			loop:
				mov AL, 10;
				out 0x70, AL;
				in AL, 0x71;
				test AL, 0x80;
				jne loop;

				// Get Day of Month (1 to 31)
				mov AL, 0x07;
				out 0x70, AL;
				in AL, 0x71;
				mov day, AL;

				// Get Month (1 to 12)
				mov AL, 0x08;
				out 0x70, AL;
				in AL, 0x71;
				mov month, AL;

				// Get Year (00 to 99)
				mov AL, 0x09;
				out 0x70, AL;
				in AL, 0x71;
				mov year, AL;
		}

		Date ret;

		// Convert from BCD to decimal
		ret.Day   = (((day & 0xf0) >> 4) * 10) + (day & 0xf);
		ret.Month = (((month & 0xf0) >> 4) * 10) + (month & 0xf);
		ret.Year  = (((year & 0xf0) >> 4) * 10) + (year & 0xf);
		ret.Year += 2000;

		return ret;
	}


	Time CurrentTime() {
		ubyte s, h, m;

		asm {
			loop:
				mov AL, 10;
				out 0x70, AL;
				in AL, 0x71;
				test AL, 0x80;
				jne loop;

				// Get Seconds
				mov AL, 0x00;
				out 0x70, AL;
				in AL, 0x71;
				mov s, AL;

				// Get Minutes
				mov AL, 0x02;
				out 0x70, AL;
				in AL, 0x71;
				mov m, AL;

				// Get Hours
				mov AL, 0x04;
				out 0x70, AL;
				in AL, 0x71;
				mov h, AL;
		}

		if ((h & 128) == 128) {
			h = h & 0b0111_1111;
			h += 12;
		}

		Time ret;

		// Convert from BCD to decimal
		ret.Hours = (((h & 0xf0) >> 4) * 10) + (h & 0xf);
		ret.Minutes = (((m & 0xf0) >> 4) * 10) + (m & 0xf);
		ret.Seconds = (((s & 0xf0) >> 4) * 10) + (s & 0xf);

		return ret;
	}
}
