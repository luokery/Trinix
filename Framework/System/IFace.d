module System.IFace;


class IFace {
	enum FSNode : ulong {
		OBJECT = 0x1,

		TYPE,
		SFIND,
		SMKDIR,
		GETUID,
		GETGID,
		SETCWD,
		REMOVE,
		SGETRFN,
		SGETCWD,
		GETNAME,
		GETPERM,
		GETPATH,
		GETPARENT,
		GETLENGTH,
		GETNCHILD,
		GETIDXCHILD,
	}
}

/*
enum : ushort {
	VTIF_OBJTYPE,
	PRIF_OBJTYPE,
	THIF_OBJTYPE,
	FLIF_OBJTYPE,
	FNIF_OBJTYPE,
	SYIF_OBJTYPE
}*/