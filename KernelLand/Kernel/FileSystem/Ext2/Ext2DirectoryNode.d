﻿module FileSystem.Ext2.Ext2DirectoryNode;

import VFSManager;
import FileSystem.Ext2;


public final class Ext2DirectoryNode : DirectoryNode {
	package Ext2Filesystem.Inode _inode;
	private bool _loadedAttribs;
	
	public this(int inode, DirectoryNode parent, FileAttributes attributes) {
		if (parent !is null && parent.FileSystem !is null)
			(cast(Ext2Filesystem)parent.FileSystem).ReadInode(_inode, inode);
		
		super(parent, attributes);
	}
	
	@property public override FileAttributes Attributes() {
		if (!_loadedAttribs && FileSystem !is null) {
			auto attribs = (cast(Ext2Filesystem)FileSystem).GetAttributes(_inode);
			attribs.Name = _attributes.Name;
			attribs.Type = _attributes.Type;

			_attributes = attribs;
			_loadedAttribs = true;
		}
		
		return _attributes;
	}
	
	@property public override void Attributes(FileAttributes value) {
		_attributes = value; //TODO
	}
}