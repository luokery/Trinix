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
 * 
 * TODO:
 *      o Not working in IDT and Paging
 */

module Core.Logger;

import Architecture;
import ObjectManager;

/*
abstract final class Log {
	__gshared int Base = 16;

	private __gshared DisplayChar* _display = cast(DisplayChar *)0xFFFFFFFF800B8000;
	private __gshared int _iterator;
	private __gshared int _padding;

	static bool Initialize() {
		//Set cursor
		Port.Write!byte(0x3D4, 0x0F);
		Port.Write!byte(0x3D5, 0);
		Port.Write!byte(0x3D4, 0x0E);
		Port.Write!byte(0x3D5, 0);
		
		//Clear screen
		foreach (i; 0 .. 2000)
			_display[i].Address = 0;

		SerialPort.Open();
		return true;
	}

	static void NewLine() {
		Scroll();
		_iterator += 80 - (_iterator % 80);
		SerialPort.Write("\n");
	}

	static void WriteJSON(T...)(T args) {
		bool first;
		foreach (x; args) {
			alias A = typeof(x);

			static if (is(A == string)) {
				if (x == "{" || x == "[" || x == "}" || x == "]") {
					if (_padding && (x == "}" || x == "]"))
						_padding--;

					version (LogUserFriendly)
						if (!first)
							foreach (i; 0 .. _padding * 4)
								Write(" ");

					Write(x);

					version (LogUserFriendly)
						NewLine();

					if (x == "{" || x == "[")
						_padding++;
					continue;
				}
			} else static if (is(A == char)) {
				if (x == '{' || x == '[' || x == '}' || x == ']') {
					if (_padding && (x == '}' || x == ']'))
						_padding--;

					version (LogUserFriendly)
						if (!first)
							foreach (i; 0 .. _padding * 4)
								Write(" ");

					Write(x);

					version (LogUserFriendly)
						NewLine();

					if (x == '{' || x == '[')
						_padding++;
					continue;
				}
			}

			if (!first) {
				version (LogUserFriendly)
					foreach (i; 0 .. _padding * 4)
						Write(" ");

				Write("\"", x, "\": ");
				first = true;
			} else {
				Write("\"", x, "\",");

				version (LogUserFriendly)
					NewLine();
				first = false;
			}
		}
	}

	static void WriteLine(T...)(T args) {
		Write(args);
		NewLine();
	}

	static void Write(T...)(T args) {
		foreach (x; args) {
			alias A = typeof(x);

			static if (is(A == struct) || is(A == class) || is(A == union) || is(A == interface))
				ParseBlock(x);
			else static if (is(A == string) || is(A == const char[]) || is(A == char[]))
				Put(cast(string)x);
			else static if (is(A == char))
				Put(cast(string)(cast(char *)&x)[0 .. 1]);
			else static if (is(A == long)  || is(A == ulong)  || is(A == int)  || is(A == uint) ||
			                is(A == short) || is(A == ushort) || is(A == byte) || is(A == ubyte))
				PrintNum(x);
			else static if (is(A == enum))
				PrintNum(cast(ulong)x);
			else static if (is(A == bool))
				Put(x ? "True" : "False");
			else static if (is(typeof({ foreach(elem; T.init) {} }))) {
				Write('[', x[0]);
				foreach (y; x[1 .. $])
					Write(", ", y);
				Put("]");
			} else
				Write("Unknown Type: ", A.stringof);
		}
	}

	private static void ParseBlock(T)(T args) {
		auto values = args.tupleof;

		WriteJSON('{');
		foreach (index, value; values)
			WriteJSON(T.tupleof[index].stringof, value);
		WriteJSON('}');
	}

	static void Put(string str) {
		Scroll();
		Print(str, 0, _iterator);
		SerialPort.Write(str);
		_iterator += str.length;
	}

	private static void Scroll() {
		if (_iterator > 80 * 25) {
			_display[0 .. _iterator - 80] = _display[80 .. _iterator];
			_display[_iterator - 80 .. _iterator] = cast(DisplayChar)0;
			_iterator -= 80;
		}
	}

	private static void Print(string str, uint line, uint offset = 0, byte color = 0x7) {
		foreach (i; 0 .. str.length) {
			_display[line * 80 + offset + i].Char = str[i];
			_display[line * 80 + offset + i].Color = color;
		}
	}

	private static void PrintNum(T)(T number) {
		if (!number) {
			Put("0");
			return;
		}
		
		if (number < 0) {
			Put("-");
			number = -number;
		}

		if (Base == 16)
			Put("0x");
		else if (Base == 8)
			Put("0");
		else if (Base == 2)
			Put("0b");

		char buf[32];
		int i;
		for(i = 30; number && i; --i, number /= Base)
			buf[i] = "0123456789ABCDEF"[number % Base];

		Put(cast(immutable char[])buf[i + 1.. $ - 1]);
	}

	private union DisplayChar {
		struct {
			char Char;
			byte Color;
		}
		ushort Address;
	}

	private abstract final static class SerialPort {
		private enum port = 0x3F8;
		
		private static void Open() {
			Port.Write!ubyte(cast(short)(port + 1), 0x00);
			Port.Write!ubyte(cast(short)(port + 3), 0x80);
			Port.Write!ubyte(cast(short)(port + 0), 0x03);
			Port.Write!ubyte(cast(short)(port + 1), 0x00);
			Port.Write!ubyte(cast(short)(port + 3), 0x03);
			Port.Write!ubyte(cast(short)(port + 2), 0xC7);
			Port.Write!ubyte(cast(short)(port + 4), 0x0B);
		}
		
		private static bool Recieved() {
			return (Port.Read!ubyte(cast(short)(port + 5)) & 1) != 0;
		}
		
		private static bool IsTransmitEmpty() {
			return (Port.Read!byte(cast(short)(port + 5)) & 0x20) != 0;
		}
		
		private static void Write(char c) {
			while (!IsTransmitEmpty()) {}
			Port.Write!ubyte(port, c);
		}
		
		private static void Write(string text) {
			foreach (x; text)
				Write(x);
		}
		
		private static char Read() {
			return Recieved() ? Port.Read!ubyte(port) : 0;
		}
	}
}
*/







import core.vararg;


abstract final class Logger {
    private __gshared DisplayChar* _display = cast(DisplayChar *)0xFFFFFFFF800B8000;
    private __gshared int _iterator;

    private union DisplayChar {
        struct {
            char Char;
            byte Color;
        }
        ushort Address;
    }
    
    static bool Initialize() {
        //Set cursor
        Port.Write!byte(0x3D4, 0x0F);
        Port.Write!byte(0x3D5, 0);
        Port.Write!byte(0x3D4, 0x0E);
        Port.Write!byte(0x3D5, 0);
        
        //Clear screen
        foreach (i; 0 .. 2000)
            _display[i].Address = 0;

        return true;
    }

    static void Write(string format, ...) {
        char[1024] buffer;
        
        long len = ParseString(buffer, format, _arguments, _argptr);
        Put(buffer[0 .. len]);
    }

    static void WriteLine(string format, ...) {
        char[1024] buffer;
        
        long len = ParseString(buffer, format, _arguments, _argptr);
        Put(buffer[0 .. len]);
        Put(cast(char[])"\n");
    }

    private static void PrintDecimal(ulong value, int width, char[] buffer, ref int ptr) {
        uint nWidth = 1;
        uint i = 9;

        while (value > i && i < ~0UL) {
            nWidth++;
            i *= 10;
            i += 9;
        }

        while (width-- > nWidth)
            buffer[ptr++] = '0';

        i = nWidth;
        while (i-- > 0) {
            buffer[ptr + i] = (value % 10) + '0';
            value /= 10;
        }

        ptr += nWidth;
    }

    private static void PrintHex(ulong value, int width, char[] buffer, ref int ptr) {
        uint nWidth = 1;
        uint i = 0x0F;
        
        while (value > i && i < ~0UL) {
            nWidth++;
            i *= 0x10;
            i += 0x0F;
        }

        buffer[ptr++] = '0';
        buffer[ptr++] = 'x';

        while (width-- > nWidth)
            buffer[ptr++] = '0';
        
        i = nWidth;
        while (i-- > 0)
            buffer[ptr + i] = "0123456789ABCDEF"[(value >> (i * 4)) & 0x0F];
        
        ptr += nWidth;
    }

    private static long ParseString(char[] buffer, string format, TypeInfo[] _arguments, va_list _argptr) {
        int ptr, a;

        for (int i = 0, j = 0; i < format.length; i++) {
            if (format[i] != '%') {
                buffer[ptr++] = format[i];
                continue;
            }
            i++;

            uint argWidth;
            while (format[i] >= '0' && format[i] <= '9') {
                argWidth *= 10;
                argWidth += format[i]  - '0';
                i++;
            }

            switch (format[i]) {
                case '%':
                    buffer[ptr++] = '%';
                    break;

                case 'c':
                    if (_arguments[j] == typeid(char)) {
                        auto s = va_arg!char(_argptr);
                        j++;

                        buffer[ptr++] = s;
                    }
                    break;

                case 's':
                    if (_arguments[j] == typeid(string)) {
                        auto s = va_arg!string(_argptr);
                        j++;

                        if (s == null)
                          s = "(null)";
                        
                           foreach (x; s)
                              buffer[ptr++] = x;
                    }
                    break;

                case 'd':
                    if (_arguments[j] == typeid(byte)  || _arguments[j] == typeid(ubyte)  || //TODO implement isNumeric from phobos
                        _arguments[j] == typeid(short) || _arguments[j] == typeid(ushort) ||
                        _arguments[j] == typeid(int)   || _arguments[j] == typeid(uint)   ||
                        _arguments[j] == typeid(long)  || _arguments[j] == typeid(ulong)) {
                        auto s = va_arg!long(_argptr);
                        j++;

                        PrintDecimal(s, argWidth, buffer, ptr);
                    }
                    break;

                case 'x':
                    if (_arguments[j] == typeid(byte)  || _arguments[j] == typeid(ubyte)  || //TODO implement isNumeric from phobos
                        _arguments[j] == typeid(short) || _arguments[j] == typeid(ushort) ||
                        _arguments[j] == typeid(int)   || _arguments[j] == typeid(uint)   ||
                        _arguments[j] == typeid(long)  || _arguments[j] == typeid(ulong)) {
                        auto s = va_arg!long(_argptr);
                        j++;

                        PrintHex(s, argWidth, buffer, ptr);
                    }
                    break;

                default:
            }
        }

        return ptr;
    }



    //TODO
    private static void NewLine() {
        Scroll();
        _iterator += 80 - (_iterator % 80);
    }

    private static void Put(char[] str) {
        Scroll();
        Print(str, 0, _iterator);
        _iterator += str.length;
    }
    
    private static void Scroll() {
        if (_iterator > 80 * 25) {
            _display[0 .. _iterator - 80] = _display[80 .. _iterator];
            _display[_iterator - 80 .. _iterator] = cast(DisplayChar)0;
            _iterator -= 80;
        }
    }
    
    private static void Print(char[] str, uint line, uint offset = 0, byte color = 0x7) {
        foreach (i; 0 .. str.length) {
            if (str[i] == '\n') {
                NewLine();
                continue;
            } else if (str[i] == '\t') {
                int n = (offset + i) % 4;

                foreach (j; 0 .. n) {
                    _display[line * 80 + offset + i].Char = str[i];
                    _display[line * 80 + offset + i].Color = color;
                    offset++;
                    continue;
                }
            }

            _display[line * 80 + offset + i].Char = str[i];
            _display[line * 80 + offset + i].Color = color;
        }
    }
}

alias Log = Logger.WriteLine;