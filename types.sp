#if !defined TYPES_SP
#define TYPES_SP

/********** Defines **********/
#define MAX_VOTE_TYPES 28

#define MAX_INPUT_SIZE 128
#define MAX_CONVAR_SIZE 256

#define WARMUP_TIME 5
#define WAITING_TIME 5
#define VOTE_COOLDOWN_TIME 3

#define VOTE_PERCENTAGE 60
#define KIT_SPREAD_PERCENTAGE 70 // 1 == random, 2 == everyone

#define MINIMUM_PLAYERS 2
#define MINIMUM_PISTOL_ROUNDS 2

#define WINSTREAK_MAX 6

#define RETAKE_PREFIX "[Retakes]"

/********** Enums **********/
enum SpawnType
{
    CT          = 0x00000001,
    T           = 0x00000002,
    BOMBER      = 0x00000002 | 0x00000004,
};

enum RoundTypes
{
    WARMUP          = 0x00000001,
    WAITING         = 0x00000002,
    EDIT            = 0x00000004,
    PISTOL_ROUND    = 0x00000008,
    FULLBUY_ROUND   = 0x00000010,
    DEAGLE_ROUND    = 0x00000020,
    TIMER_END       = 0x00000040,
};

enum WeaponsSlot
{
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

    /** Utility / Misc **/
    FLASHBANG       = 0x00010000,
    SMOKEGRENADE    = 0x00020000,
    HEGRENADE       = 0x00040000,
    MOLOTOV         = 0x00080000,
    INCENDIARY      = 0x00100000,
    FLASHBANG_2ND   = 0x00200000,
    UTILITY_MASK    = 0x003F0000,
    UTILITY_T_MASK  = 0x002F0000,
    UTILITY_CT_MASK = 0x00370000,

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
}

enum struct Queue {
    int data[MAXPLAYERS];
    int len;

    bool insert(int client) {
        if (IsClientSourceTV(client)) {
            return false;
        }

        if ((MAXPLAYERS - 1) == this.len) {
            return false;
        }
    
        int index = this.get_index(client);
        if (-1 != index) {
            this.pop(index);
        }

        this.data[this.len] = client;
    
        this.len++;
        PrintToChat(client, "You are now %d place in the queue", this.len);

        return true;
    }

    int pop(int index = 0) {
        if (this.len == 0 || index >= this.len || index < 0) {
            return -1;
        }

        int value = this.data[index];

        for (int i = index; i < this.len; i++) {
            this.data[i] = this.data[i + 1];

            if (0 != this.data[i]) {
                PrintToChat(this.data[i], "You are now %d place in the queue", i + 1);
            }
        }

        this.data[this.len--] = 0;

        return value;
    }

    void print_queue() {
        for (int i = 0; i < this.len; i++) {
            PrintToChatAll("data[%d] = %d", i, this.data[i]);
        }
    }

    int get_index(int client) {
        for (int i = 0; i < this.len; i++) {
            if (this.data[i] == client) {
                return i;
            }
        }
        return -1;
    }
}

#endif // TYPES_SP