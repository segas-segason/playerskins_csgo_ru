#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "6.0.1 (Build 13)"
#define PLUGIN_AUTHOR "noBrain and segas"
#define MAX_SKIN_PATH 256

Database db = null;


ConVar g_cMapSkins = null;


char defArms[][] = { "models/weapons/ct_arms.mdl", "models/weapons/t_arms.mdl" };

//Define PathOfFile
char g_szFileSkinPath[PLATFORM_MAX_PATH], g_szFileAutoSkinPath[PLATFORM_MAX_PATH], g_szFileUserSkinPath[PLATFORM_MAX_PATH], g_szFileMapSkins[PLATFORM_MAX_PATH];



public Plugin myinfo =  {

	name = "Player Skins",
	author = PLUGIN_AUTHOR,
	description = "Allow players to select their skins.",
	version = PLUGIN_VERSION,

};

public void OnPluginStart() 
{

	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Pre);
	
	g_cMapSkins = CreateConVar("sm_mapskins_enable", "1", "Enable/Disable per map skin system");
	
	//Delay loading database.
	
	//Define Created Paths	
	
	BuildPath(Path_SM, g_szFileMapSkins, sizeof(g_szFileMapSkins), "configs/playerskins/mapskins.ini");
	
	//Auto-Create Configurations
	AutoExecConfig(true, "configs.playerskin");
	
	//Load Translations
	LoadTranslations("pskin.phrases.txt");
}

public void OnConfigsExecuted()
{
	PrintToServer("[PlayerSkin] Configs has executed.");
}

public void OnMapStart() 
{
	CreateDatabase();
	PrecacheAllModels();
}


public Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidClient(client) || IsFakeClient(client)){
		return;
	}
	if(IsUserWithSkins(client))
	{
		char UserSkin[MAX_SKIN_PATH], UserArms[MAX_SKIN_PATH];
		int i_iTeamNumber = GetClientTeam(client);
		GetUserSkins(client, UserSkin, sizeof(UserSkin), UserArms, sizeof(UserArms), i_iTeamNumber);
		SetModels(client, UserSkin, UserArms);
	}
	else if(ApplyUserSkin(client))
	{
		PrintToConsole(client, "[PlayerSkin] You have gained your skins!");
	}
	else if(GetConVarBool(g_cMapSkins))
	{
		if(ApplyMapSkins(client))
		{
			PrintToConsole(client, " [PlayerSkin] ", "ApplyMapSkins", client);
		}
	}
	return;

}

stock bool SetModels(int client, char[] model, char[] arms)
{
	if(!IsModelPrecached(model))
	{
		PrecacheModel(model)
	}
	
	if(!IsModelPrecached(arms))
	{
		PrecacheModel(arms)
	}
	
	if(!StrEqual(model, "", false))
	{
		SetEntityModel(client, model);
		
		if(!StrEqual(arms, "", false))
		{
			SetEntPropString(client, Prop_Send, "m_szArmsModel", arms);
		}
		else
		{
			int g_iTeam = GetClientTeam(client);
			if(g_iTeam == 2)
			{
				SetEntPropString(client, Prop_Send, "m_szArmsModel", defArms[1]);
			}
			else if(g_iTeam == 3)
			{
				SetEntPropString(client, Prop_Send, "m_szArmsModel", defArms[0]);
			}
		}
		
		return true;
	}
	else
	{
		return false;
	}
}

stock bool ApplyUserSkin(int client)
{
	char SteamAuth[32];
	GetClientAuthId(client, AuthId_SteamID64, SteamAuth, sizeof(SteamAuth));
	Handle kv = CreateKeyValues("userids");
	FileToKeyValues(kv, g_szFileUserSkinPath);
	if(KvJumpToKey(kv, SteamAuth, false))
	{
		char g_szSkins[128], g_szArms[128];
		int g_iTeamNum = GetClientTeam(client);
		if(g_iTeamNum == 2)
		{
			if(KvJumpToKey(kv, "T", false))
			{
				KvGetString(kv, "Skin", g_szSkins, sizeof(g_szSkins));
				KvGetString(kv, "Arms", g_szArms, sizeof(g_szArms));
				if(SetModels(client, g_szSkins, g_szArms))
				{
					return true;
				}
				else
				{
					return false;
				}
			}
			else
			{
				CloseHandle(kv);
				return false;
			}
		}
		else if(g_iTeamNum == 3)
		{
			if(KvJumpToKey(kv, "CT", false))
			{
				KvGetString(kv, "Skin", g_szSkins, sizeof(g_szSkins));
				KvGetString(kv, "Arms", g_szArms, sizeof(g_szArms));
				if(SetModels(client, g_szSkins, g_szArms))
				{
					return true;
				}
				else
				{
					return false;
				}
			}
			else
			{
				CloseHandle(kv);
				return false;
			}
		}
		else
		{
			CloseHandle(kv);
			return false;
		}
	}
	else
	{
		CloseHandle(kv);
		return false;
	}
}

stock void PrecacheAllModels()
{
	char Arms[128], Skin[128];
	PrecacheModel(defArms[0]);
	PrecacheModel(defArms[1]);

	Handle kv = CreateKeyValues("Skins");
	Handle kt = CreateKeyValues("Admin_Skins");
	FileToKeyValues(kv, g_szFileSkinPath);
	FileToKeyValues(kt, g_szFileAutoSkinPath);
	KvGotoFirstSubKey(kv, false);
	KvGotoFirstSubKey(kt, false);

	do 
	{
	
		KvGetString(kv, "Skin", Skin, sizeof(Skin), "");
		KvGetString(kv, "Arms", Arms, sizeof(Arms), "");

		if(!StrEqual(Arms, "")) 
		{
			PrecacheModel(Arms);
		}

		if(!StrEqual(Skin, ""))
		{
			PrecacheModel(Skin);
		}

	} while (KvGotoNextKey(kv, false));
	
	do 
	{
	
		KvGetString(kt, "SkinT", Skin, sizeof(Skin), "");
		KvGetString(kt, "ArmsT", Arms, sizeof(Arms), "");
		if(!StrEqual(Arms, "")) 
		{
			PrecacheModel(Arms);
		}
		if(!StrEqual(Skin, ""))
		{
			PrecacheModel(Skin);
		}

	} while (KvGotoNextKey(kt, false));
	
	do 
	{
	
		KvGetString(kt, "SkinCT", Skin, sizeof(Skin), "");
		KvGetString(kt, "ArmsCT", Arms, sizeof(Arms), "");
		if(!StrEqual(Arms, "")) 
		{
			PrecacheModel(Arms);
		}
		if(!StrEqual(Skin, ""))
		{
			PrecacheModel(Skin);
		}

	} while (KvGotoNextKey(kt, false));

	CloseHandle(kv);
	CloseHandle(kt);
}

stock bool ApplyMapSkins(int client)
{
	// PrintToServer("I got called!");
	char TeamCTSkin[128], TeamTSkin[128], TeamCTArms[128], TeamTArms[128], CurrentMapName[32];
	GetCurrentMap(CurrentMapName, sizeof(CurrentMapName));	
	Handle kv = CreateKeyValues("mapskins");
	FileToKeyValues(kv, g_szFileMapSkins);
	if(KvJumpToKey(kv, CurrentMapName, false))
	{
		if(GetClientTeam(client) == 2)
		{
			if(KvJumpToKey(kv, "T", false))
			{
				KvGetString(kv, "Skin", TeamTSkin, sizeof(TeamTSkin), "");
				KvGetString(kv, "Arms", TeamTArms, sizeof(TeamTArms), "");
				if(SetModels(client, TeamTSkin, TeamTArms))
				{
					return true;
				}
				else
				{
					CloseHandle(kv);
					return false;
				}
			}
		}
		else if(GetClientTeam(client) == 3)
		{
			if(KvJumpToKey(kv, "CT", false))
			{
				KvGetString(kv, "Skin", TeamCTSkin, sizeof(TeamCTSkin), "");
				KvGetString(kv, "Arms", TeamCTArms, sizeof(TeamCTArms), "");
				if(SetModels(client, TeamCTSkin, TeamCTArms))
				{
					return true;
				}
				else
				{
					CloseHandle(kv);
					return false;
				}
			}
		}
		else
		{
			//PrintToServer("NO TEAM");
			CloseHandle(kv);
			return false;
		}
	}
	else
	{
		//PrintToServer("No MAP");
		CloseHandle(kv);
		return false;
	}
	
	return false;
}

stock bool IsValidClient(int client){
	if( MaxClients > client > 0 && IsClientConnected(client) && IsClientInGame(client)){
		return true;
	}else{
		return false;
	}
}



///////////////////////////////
//			Database
///////////////////////////////

stock void CreateDatabase()
{
	char err[255];
	db = SQL_Connect("PlayerSkins", true, err, sizeof(err));
	if (db == null)
	{
		PrintToServer("[PlayerSkin] Cannot connect to the database, error: %s", err);
	}
	else
	{
		if (!SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS userskins (id VARCHAR NOT NULL, t_skin VARCHAR NOT NULL, t_arm VARCHAR NOT NULL, ct_skin VARCHAR NOT NULL, ct_arm VARCHAR NOT NULL);"))
		{
			SQL_GetError(db, err, sizeof(err));
			PrintToServer("[PlayerSkin] Failed to create the table, error: %s", err);
		}
		else
		{
			PrintToServer("[PlayerSkin] Table has created if not existed.");
		}
	}
}


stock bool AddUserSkin(int client, char[] skin, char[] arms, int team)
{
	char err[255], SteamAuth[32];
	GetClientAuthId(client, AuthId_Steam2, SteamAuth, sizeof(SteamAuth));
	if (db == null)
	{
		PrintToServer("[PlayerSkin] Cannot connect to the database, error: %s", err);
		return false;
	}
	else
	{
		if (IsUserOnDatabase(client))
		{
			PrintToServer("[PlayerSkin] User is already on database");
			char Query[512];
			
			if(team == 2)
			{
				Format(Query, sizeof(Query), "UPDATE userskins SET t_skin='%s', t_arm='%s' WHERE id='%s'", skin, arms, SteamAuth);
				if (SQL_FastQuery(db, Query))
				{
					return true;
				}
				else
				{
					return false;
				}
			}
			else if(team == 3)
			{
				Format(Query, sizeof(Query), "UPDATE userskins SET ct_skin='%s', ct_arm='%s' WHERE id='%s'", skin, arms, SteamAuth);
				if (SQL_FastQuery(db, Query))
				{
					return true;
				}
				else
				{
					return false;
				}
			}
			else
			{
				return false;
			}
		}
		else
		{
			PrintToServer("[PlayerSkin] New user data being inserted.");
			DBStatement statement = null;
			char Query[512];
			
			if(team == 2)
			{
				Format(Query, sizeof(Query), "INSERT INTO userskins (id, ct_skin, ct_arm, t_skin, t_arm) VALUES(? ,?, ?, ?, ?)");
				
				statement = SQL_PrepareQuery(db, Query, err, sizeof(err));
				if (statement == null)
				{
					PrintToServer("[PlayerSkin] An error occured, error: %s", err);
					delete statement;
					return false;
				}
				else
				{
					SQL_BindParamString(statement, 0, SteamAuth, false);
					SQL_BindParamString(statement, 0, SteamAuth, false);
					SQL_BindParamString(statement, 1, "", false);
					SQL_BindParamString(statement, 2, "", false);
					SQL_BindParamString(statement, 3, skin, false);
					SQL_BindParamString(statement, 4, arms, false);
					
					if (!SQL_Execute(statement))
					{
						delete statement;
						PrintToServer("[PlayerSkin] SQL did not executed: %s", err);
						return false;
					}
					else
					{
						delete statement;
						PrintToServer("[PlayerSkin] SQL executed.");
						return true;
					}
				}
			}
			else if(team == 3)
			{
				Format(Query, sizeof(Query), "INSERT INTO userskins (id, ct_skin, ct_arm, t_skin, t_arm) VALUES(? ,?, ?, ?, ?)");
				
				statement = SQL_PrepareQuery(db, Query, err, sizeof(err));
				if (statement == null)
				{
					PrintToServer("[PlayerSkin] An error occured, error: %s", err);
					delete statement;
					return false;
				}
				else
				{
					SQL_BindParamString(statement, 0, SteamAuth, false);
					SQL_BindParamString(statement, 1, skin, false);
					SQL_BindParamString(statement, 2, arms, false);
					SQL_BindParamString(statement, 3, "", false);
					SQL_BindParamString(statement, 4, "", false);
					
					if (!SQL_Execute(statement))
					{
						delete statement;
						return false;
					}
					else
					{
						delete statement;
						return true;
					}
				}
			}
			else
			{
				return false;
			}
		}
	}
}

stock bool DeleteUserSkin(int client, int team)
{
	char err[255], SteamAuth[32];
	GetClientAuthId(client, AuthId_Steam2, SteamAuth, sizeof(SteamAuth));
	if (db == null)
	{
		PrintToServer("[PlayerSkin] Cannot connect to the database, error: %s", err);
		return false;
	}
	else
	{
		if (IsUserOnDatabase(client))
		{
			PrintToServer("[PlayerSkin] User is already on database");
			char Query[128];
			
			// Format(Query, sizeof(Query), "DELETE FROM userskins WHERE id='%s'", SteamAuth);
			
			if(team == 2)
			{
				Format(Query, sizeof(Query), "UPDATE userskins SET t_skin='', t_arm='' WHERE id='%s'", SteamAuth);
				if (SQL_FastQuery(db, Query))
				{
					return true;
				}
				else
				{
					return false;
				}
			}
			else if(team == 3)
			{
				Format(Query, sizeof(Query), "UPDATE userskins SET ct_skin='', ct_arm='' WHERE id='%s'", SteamAuth);
				if (SQL_FastQuery(db, Query))
				{
					return true;
				}
				else
				{
					return false;
				}
			}
			else
			{
				return false;
			}
			
		}
		else
		{
			return false;
		}
	}
}

stock bool IsUserOnDatabase(int client)
{
	char Query[128], SteamAuth[32], err[255];
	GetClientAuthId(client, AuthId_Steam2, SteamAuth, sizeof(SteamAuth));
	DBResultSet hQuery = null;
	Format(Query, sizeof(Query), "SELECT * FROM userskins");
	hQuery = SQL_Query(db, Query);
	while (SQL_FetchRow(hQuery))
	{
		SQL_FetchString(hQuery, 0, Query, sizeof(Query));
		if (StrEqual(Query, SteamAuth, false))
		{
			delete hQuery;
			return true;
		}
	}
	
	delete hQuery;
	return false;
}

stock void GetUserSkins(int client, char[] skin, int maxskinlen, char[] arms, int maxarmslen, int team)
{
	DBResultSet hQuery = null;
	char Query[128], SteamAuth[32];
	GetClientAuthId(client, AuthId_Steam2, SteamAuth, sizeof(SteamAuth));
	
	if(IsUserOnDatabase(client))
	{
		if(team == 2)
		{
			Format(Query, sizeof(Query), "SELECT t_skin, t_arm FROM userskins WHERE id = '%s'", SteamAuth);
			
			hQuery = SQL_Query(db, Query);
			if (hQuery == null)
			{
				PrintToServer("[PlayerSkin] Could not execute the query.");
				Format(skin, maxskinlen, "");
				Format(arms, maxarmslen, "");
			}
			else
			{
				SQL_FetchString(hQuery, 0, skin, maxskinlen);
				SQL_FetchString(hQuery, 1, arms, maxarmslen);
			}
		}
		else if(team == 3)
		{
			Format(Query, sizeof(Query), "SELECT ct_skin, ct_arm FROM userskins WHERE id = '%s'", SteamAuth);
			
			hQuery = SQL_Query(db, Query);
			if (hQuery == null)
			{
				PrintToServer("[PlayerSkin] Could not execute the query.");
				Format(skin, maxskinlen, "");
				Format(arms, maxarmslen, "");
			}
			else
			{
				SQL_FetchString(hQuery, 0, skin, maxskinlen);
				SQL_FetchString(hQuery, 1, arms, maxarmslen);
			}
		}
		else
		{
			Format(skin, maxskinlen, "");
			Format(arms, maxarmslen, "");
		}
	}
	else
	{
		Format(skin, maxskinlen, "");
		Format(arms, maxarmslen, "");
	}
}


stock bool IsUserWithSkins(int client)
{
	DBResultSet hQuery = null;
	char Query[128], SteamAuth[32], SkinsPath[MAX_SKIN_PATH], ArmsPath[MAX_SKIN_PATH];
	GetClientAuthId(client, AuthId_Steam2, SteamAuth, sizeof(SteamAuth));
	int team = GetClientTeam(client);
	
	// PrintToServer("#1");
	
	if(IsUserOnDatabase(client))
	{
		// PrintToServer("#2");
		if(team == 2)
		{
			// PrintToServer("#3");
			Format(Query, sizeof(Query), "SELECT t_skin, t_arm FROM userskins WHERE id = '%s'", SteamAuth);
			
			hQuery = SQL_Query(db, Query);
			if (hQuery == null)
			{
				PrintToServer("[PlayerSkin] Could not execute the query.");
				return false;
			}
			else
			{
				SQL_FetchString(hQuery, 0, SkinsPath, sizeof(SkinsPath));
				SQL_FetchString(hQuery, 1, ArmsPath, sizeof(ArmsPath));
				
				// PrintToServer("IsUserWithSkins Has Passed Execution.");
				// PrintToServer("UserSkin: %s", SkinsPath);
				
				if(!StrEqual(SkinsPath, "", false))
				{
					return true;
				}
				else
				{
					return false;
				}
			}
		}
		else if(team == 3)
		{
			Format(Query, sizeof(Query), "SELECT ct_skin, ct_arm FROM userskins WHERE id = '%s'", SteamAuth);
			
			hQuery = SQL_Query(db, Query);
			if (hQuery == null)
			{
				PrintToServer("[PlayerSkin] Could not execute the query.");
				return false;
			}
			else
			{
				SQL_FetchString(hQuery, 0, SkinsPath, sizeof(SkinsPath));
				SQL_FetchString(hQuery, 1, ArmsPath, sizeof(ArmsPath));
				
				// PrintToServer("IsUserWithSkins Has Passed Execution.");
				// PrintToServer("UserSkin: %s", SkinsPath);
				
				if(!StrEqual(SkinsPath, "", false))
				{
					return true;
				}
				else
				{
					return false;
				}
			}
		}
		else
		{
			return false;
		}
	}
	else
	{
		return false;
	}
}
