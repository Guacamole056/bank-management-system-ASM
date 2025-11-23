Bank Management System - x86 Assembly Version
==============================================

This is a simplified x86 assembly conversion of the C bank management system.

COMPILATION INSTRUCTIONS:
-------------------------
1. Make sure you have MASM and the Irvine32 library installed
2. Update the path in ```build.bat``` to point to your Irvine library location
3. Run: ```build.bat```

Or manually:  
```
ml /c /I"C:\Irvine" bank_system.asm  
link /SUBSYSTEM:CONSOLE bank_system.obj Irvine32.lib kernel32.lib user32.lib
```
FEATURES:
---------
- User authentication (login, create account)
- Admin menu with full account management
- User menu for balance inquiry and transfers
- Account operations: add, view, edit, delete
- Transactions: debit, credit, transfer
- Loyalty points system

DEFAULT ADMIN ACCOUNT:
----------------------
Username: admin  
Password: admin

NOTE:
-----
- File I/O has been excluded for simplicity
- All data is stored in memory (lost on exit)
- Uses integer arithmetic instead of floating point
- Simplified for school project requirements
