DefinitionBlock ("", "SSDT", 2, "HACK", "ASUSFN", 0x00000000)
{
    External (_SB.PC00.LPCB.EC0, DeviceObj)
    External (_SB.PC00.LPCB.EC0.SLKB, MethodObj)    // 1 Arguments
    External (_SB.PC00.LPCB.PS2K, DeviceObj)
    External (_SB.KBLC, FieldUnitObj)
    External (_SB.KBLV, FieldUnitObj)

    Scope (_SB.PC00.LPCB.EC0)
    {
        // Fn+F4 / Fn+F5: brightness down / up (PS/2 e005 / e006 -> BrightnessKeys)
        Method (_Q0E, 0, NotSerialized)
        {
            Notify (\_SB.PC00.LPCB.PS2K, 0x0405)
        }

        Method (_Q0F, 0, NotSerialized)
        {
            Notify (\_SB.PC00.LPCB.PS2K, 0x0406)
        }

        // Keyboard backlight down (EC query 0C): one level down, stops at off
        Method (_Q0C, 0, NotSerialized)
        {
            If ((\_SB.KBLC & 0x80))
            {
                Local0 = (\_SB.KBLV & 0x03)
                If (Local0)
                {
                    Local0--
                }

                SLKB (Local0 | 0x80)
            }
        }

        // Fn+F7 (EC query 0D): off -> 1 -> 2 -> 3 -> off
        Method (_Q0D, 0, NotSerialized)
        {
            If ((\_SB.KBLC & 0x80))
            {
                Local0 = (\_SB.KBLV & 0x03)
                If ((Local0 >= 0x03))
                {
                    Local0 = Zero
                }
                Else
                {
                    Local0++
                }

                SLKB (Local0 | 0x80)
            }
        }
    }
}
