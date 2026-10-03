#Setting RestrictAnonymous and RestrictAnonymousSAM to 0 allows anonymous access. Setting EveryoneIncludesAnonymous to 1 includes anonymous users in the "Everyone" group. You may only need to use one of these to fix an issue.

New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Lsa" -Name RestrictAnonymous -Value 0 -PropertyType DWORD -Force
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Lsa" -Name RestrictAnonymousSAM -Value 0 -PropertyType DWORD -Force
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Lsa" -Name EveryoneIncludesAnonymous -Value 1 -PropertyType DWORD -Force
