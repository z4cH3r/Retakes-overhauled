#if !defined TYPES_SP
#define TYPES_SP

/********** Defines **********/
#define MAX_VOTE_TYPES          (28)

#define MAX_INPUT_SIZE          (128)
#define MAX_CONVAR_SIZE         (256)
#define MAX_SQL_QUERY_SIZE      (512)
#define MAX_SPAWN_COUNT         (64)
#define MAX_MAP_STRING_SIZE     (32)
#define MAX_INGAME_PLAYERS      (9)
#define MAX_DB_RETRIES          (20)
#define MIN_PLAYERS             (2)
#define MIN_PISTOL_ROUNDS       (5)

#define WARMUP_TIME             (5)
#define EDIT_TIME               (5)
#define WAITING_TIME            (10)
#define VOTE_COOLDOWN_TIME      (3)

#define VOTE_PERCENTAGE         (60)

#define WINSTREAK_MAX           (7) // Will scramble when winstreak >= 7

#define RETAKE_PREFIX           ("[Retakes]")
#define RETAKE_CONFIG           ("retakes")

#define CS_TEAM_ANY             (4) // Not in the original cstrike file
#define CONSOLE_CLIENT          (0)

#define FREEZETIME              (3)

#define CT_MODEL                ("models/player/ctm_idf.mdl")
#define T_MODEL                 ("models/player/tm_phoenix.mdl")
#define BOMBER_MODEL            ("models/player/tm_pirate.mdl")
#define ERROR_MODEL             ("models/error.mdl")


#define RETAKE_NOT_LIVE (WARMUP | WAITING | EDIT)

/********** Enums **********/
enum SpawnType {
    SPAWNTYPE_NONE  = 0x00000000,
    BOMBER          = 0x00000001,
    T               = 0x00000002, // Same as CS_TEAM_T
    CT              = 0x00000003, // Same as CS_TEAM_CT
};

enum struct SpawnModels {
    int t_model;
    int ct_model;
    int bomber_model;
    int error_model;
}

enum Bombsite {
    A               = 0x00000000,
    B               = 0x00000001,
    BOMBSITE_NONE   = 0x00000002, // Not 0 because of legacy DB's we want to support
}

enum struct Axis {
    float x;
    float y;
    float z;
    float formatted[3];

    void Initialize() {
        this.x = 0.0;
        this.y = 0.0;
        this.z = 0.0;
    }

    void ToFormat() {
        this.formatted[0] = this.x;
        this.formatted[1] = this.y;
        this.formatted[2] = this.z;
    }
}

enum struct Spawn {
    int sql_id;
    int ent_id;
	bool is_used;
    bool is_initialized;
	Bombsite bombsite;
	SpawnType spawn_type;
	Axis spawn_angles;
	Axis spawn_location;

    void Initialize() {
        this.sql_id = -1;
        // this.ent_id = Not initializing because we keep 'cached' entity
        this.is_used = false;
        this.is_initialized = false;
        this.bombsite = BOMBSITE_NONE;
        this.spawn_type = SPAWNTYPE_NONE;
        this.spawn_angles.Initialize();
        this.spawn_location.Initialize();
    }
}

enum RoundTypes {
    WARMUP          = 1 << 0,
    WAITING         = 1 << 1,
    EDIT            = 1 << 2,
    TIMER_STARTED   = 1 << 3,
    TIMER_STOPPED   = 1 << 4,
    PISTOL_ROUND    = 1 << 5,
    FULLBUY_ROUND   = 1 << 6,
    DEAGLE_ROUND    = 1 << 7,
}

enum WeaponsSlot {
    Slot_Invalid        = -1,   /** Invalid weapon (slot). */
    Slot_Primary        = 0,    /** Primary weapon slot. */
    Slot_Secondary      = 1,    /** Secondary weapon slot. */
    Slot_Melee          = 2,    /** Melee (knife) weapon slot. */
    Slot_Projectile     = 3,    /** Projectile (grenades, flashbangs, etc) weapon slot. */
    Slot_Explosive      = 4,    /** Explosive (c4) weapon slot. */
}

enum WeaponTypes {
    WEAPON_NONE     = 0x00000000,

    /** Pistols **/
    USP             = 0x00000001,
    P2000           = 0x00000002,
    FIVESEVEN       = 0x00000004,
    GLOCK           = 0x00000008,
    TEC9            = 0x00000010,
    CZ              = 0x00000020,
    DEAGLE          = 0x00000040,
    P250            = 0x00000080,
    PISTOL_MASK     = 0x000000FF,
    PISTOL_T_MASK   = 0x000000F8,
    PISTOL_CT_MASK  = 0x000000E7,

    /** Rifles **/
    M4A1            = 0x00000100,
    M4A1S           = 0x00000200,
    AUG             = 0x00000400,
    AK47            = 0x00000800,
    SG553           = 0x00001000,
    AWP             = 0x00002000,
    RIFLE_MASK      = 0x00003F00,
    RIFLE_T_MASK    = 0x00003800,
    RIFLE_CT_MASK   = 0x00002700,

    /** Utility **/
    FLASHBANG       = 0x00010000,
    SMOKEGRENADE    = 0x00020000,
    HEGRENADE       = 0x00040000,
    MOLOTOV         = 0x00080000,
    INCENDIARY      = 0x00100000,
    FLASHBANG_2ND   = 0x00200000,
    UTILITY_MASK    = 0x003F0000,
    UTILITY_T_MASK  = 0x002F0000,
    UTILITY_CT_MASK = 0x00370000,

    /** Misc **/
    KNIFE           = 0x00400000,
    KNIFE_MASK      = 0x00400000,
    C4              = 0x00800000,
    C4_MASK         = 0x00800000,
    DEFUSE_KIT      = 0x01000000,
    DEFUSE_KIT_MASK = 0x01000000,
}

// If you add cookies, refer to line 61, 79 @ cookies.sp
enum cookies {
    cAwp,
    cAwpSecondary,
    cPrimaryT,
    cPrimaryCT,
}

enum struct ClientPref {
    bool want_awp;
    WeaponTypes awp_secondary;
    WeaponTypes primary_t;
    WeaponTypes primary_ct;

    //SetCookie(int client, cookies cookie, String:value[])
    void StoreClientCookies(int client) {
        char itoa[MAX_INPUT_SIZE];
        IntToString(this.want_awp, itoa, sizeof(itoa));
        SetCookie(client, cAwp, itoa);

        IntToString(view_as<int>(this.awp_secondary), itoa, sizeof(itoa));
        SetCookie(client, cAwpSecondary, itoa);

        IntToString(view_as<int>(this.primary_t), itoa, sizeof(itoa));
        SetCookie(client, cPrimaryT, itoa);

        IntToString(view_as<int>(this.primary_ct), itoa, sizeof(itoa));
        SetCookie(client, cPrimaryCT, itoa);
    }
}

enum struct Client {
    ClientPref pref;
    int round_damage;
    float last_command_time;
    bool votes[MAX_VOTE_TYPES];
    bool edit_menu_opened;
    bool spawnpoint_tele;
}

enum struct Queue {
    int data[MAXPLAYERS];
    int size;

    bool insert(int client) {
        if (!IsClientValid(client)) {
            return false;
        }

        if ((MAXPLAYERS - 1) == this.size) {
            return false;
        }
    
        int index = this.get_index(client);
        if (-1 != index) {
            this.pop(index);
        }

        this.data[this.size] = client;
    
        this.size++;
        PrintToChat(client, "%s You are now %d place in the queue", RETAKE_PREFIX, this.size);

        return true;
    }

    int pop(int index = 0) {
        if (this.size == 0 || index >= this.size || index < 0) {
            return -1;
        }

        int value = this.data[index];

        for (int i = index; i < this.size; i++) {
            this.data[i] = this.data[i + 1];

            if (0 != this.data[i]) {
                PrintToChat(this.data[i], "%s You are now %d place in the queue", RETAKE_PREFIX, i + 1);
            }
        }

        this.data[this.size--] = 0;

        return value;
    }

    void print_queue() {
        for (int i = 0; i < this.size; i++) {
            PrintToChatAll("data[%d] = %d", i, this.data[i]);
        }
    }

    int get_index(int client) {
        for (int i = 0; i < this.size; i++) {
            if (this.data[i] == client) {
                return i;
            }
        }
        return -1;
    }
}

#endif // TYPES_SP