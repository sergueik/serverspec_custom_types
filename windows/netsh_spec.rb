# origin:https://blogs.msdn.microsoft.com/oldnewthing/20180703-00/?p=99145
# NOTE: this test is currenlty a mock up

https://blogs.msdn.microsoft.com/oldnewthing/20180703-00/?p=99145

netsh http

    Reserved URL            : http://+:5985/wsman/
        User: NT SERVICE\WinRM
            Listen: Yes
            Delegate: No
        User: NT SERVICE\Wecsvc
            Listen: Yes
            Delegate: No
            SDDL: D:(A;;GX;;;S-1-5-80-569256582-2953403351-2909559716-1301513147-412116970)(A;;GX;;;S-1-5-80-4059739203-877974739-1245631912-527174227-2996563517)
