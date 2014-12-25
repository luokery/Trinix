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
 * Matsumoto Satoshi <satoshi@gshost.eu>
 */
module Runtime.TypeInfo.ti_creal;

import Runtime.Utilities.Hash;


class TypeInfo_c : TypeInfo { /* creal */
@trusted:
pure:
nothrow:
    package static bool _equals(creal f1, creal f2) {
        return f1 == f2;
    }
    
    package static int _compare(creal f1, creal f2) {
        int result;
        
        if (f1.re < f2.re)
            result = -1;
        else if (f1.re > f2.re)
            result = 1;
        else if (f1.im < f2.im)
            result = -1;
        else if (f1.im > f2.im)
            result = 1;
        else
            result = 0;
        return result;
    }
    
const:
    override string ToString() const pure nothrow @safe {
        return "creal";
    }
    
    override size_t GetHash(in void* p) {
        return HashOf(p, creal.sizeof);
    }
    
    override bool Equals(in void* p1, in void* p2) {
        return _equals(*cast(creal *)p1, *cast(creal *)p2);
    }
    
    override int Compare(in void* p1, in void* p2) {
        return _compare(*cast(creal *)p1, *cast(creal *)p2);
    }
    
    override @property size_t TSize() nothrow pure {
        return creal.sizeof;
    }
    
    override void Swap(void *p1, void *p2) {
        creal t;
        
        t = *cast(creal *)p1;
        *cast(creal *)p1 = *cast(creal *)p2;
        *cast(creal *)p2 = t;
    }
    
    override const(void)[] Init() nothrow pure {
        static immutable creal r;
        
        return (cast(creal *)&r)[0 .. 1];
    }
    
    override @property size_t TAlign() nothrow pure {
        return creal.alignof;
    }
    
    override int ArgTypes(out TypeInfo arg1, out TypeInfo arg2)
    {
        arg1 = typeid(real);
        arg2 = typeid(real);
        return 0;
    }
}