/*
REGISTER_GROUP.FX
Copyright (c) Microsoft Corporation, 2006. all rights reserved.
11/17/2006 3:11:36 PM (davcook)
	
*/


#if defined(pc) || defined(PC_CPU)
#define BEGIN_REGISTER_GROUP(name)
#define END_REGISTER_GROUP(name)
#else
#define BEGIN_REGISTER_GROUP(name)	[registerGroup(_register_group_##name)] cbuffer _cbuffer_##name {
#define END_REGISTER_GROUP(name) };
#endif
