INCLUDE Irvine32.inc

Account STRUCT
    accountName BYTE 20 DUP(0)
    accountPassword BYTE 20 DUP(0)
    accountID DWORD ?
    accountBalance DWORD ?
Account ENDS

; ======== COLOR CODES ======== 
; 07h: Default (Light Gray text on Black background)
; 0Bh: Cyan (For Borders/Headings)
; 0Ah: Light Green (For Success Messages)
; 0Eh: Yellow (For Input Prompts)
; 0Ch: Light Red (For Error/Fail Messages)

.data

MAX_ACCOUNTS EQU 20
ACCOUNT_SIZE EQU SIZEOF Account ; 48 bytes
ID_START EQU 1000               ; Starting ID for calculation
ADMIN_PASSWORD BYTE "admin", 0      ; hardcoded admin password

ACCOUNT_TABLE Account MAX_ACCOUNTS DUP (<>)
CurrentAccountCount DWORD 0
NextAccountID DWORD ID_START ; Account IDs start at 1000


borderLine      BYTE "=========================================", 0
heading         BYTE "      BANK MANAGEMENT SYSTEM V2.0      ", 0
menuBorder      BYTE "+---------------------------------------+", 0

; ======== Main Screen ========
mainScreenHeading BYTE "              LOGIN SCREEN             ", 0
login1          BYTE "| 1. User Login                         |", 0
login2          BYTE "| 2. Admin Login                        |", 0
login3          BYTE "| 3. Create New Account                 |", 0
login4          BYTE "| 4. Exit Program                       |", 0
loginChoice     BYTE ">> Please enter your choice (1-4): ", 0
strEnterAdminPass BYTE "Enter Admin Password: ", 0
strAdminSuccess BYTE " Admin Login Successful. Entering Main Menu.", 0
strAdminFail    BYTE " Error: Invalid Admin Password.", 0


; ======== Admin Menu Strings ========
adminMenuHeading BYTE "              ADMIN MAIN MENU          ", 0
admin1          BYTE "| 1. Add New Account                      |", 0
admin2          BYTE "| 2. Display Specific Account (by ID)     |", 0
admin3          BYTE "| 3. Display All Accounts                 |", 0
admin4          BYTE "| 4. Delete Account (by ID)               |", 0
admin5          BYTE "| 5. Edit Account Name (by ID)            |", 0
admin6          BYTE "| 6. Edit Account Balance (by ID)         |", 0
admin7          BYTE "| 7. Return to Main Screen                |", 0
adminChoice     BYTE ">> Please enter your choice (1-7): ", 0

; ======== User Menu Strings ========
userMenuHeading BYTE "              USER DASHBOARD           ", 0
user1           BYTE "| 1. View My Account Details              |", 0
user2           BYTE "| 2. Change Password                      |", 0
user3           BYTE "| 3. Withdraw Money                       |", 0
user4           BYTE "| 4. Deposit Money                        |", 0
user5           BYTE "| 5. Transfer Money                       |", 0
user6           BYTE "| 6. Logout                               |", 0
userChoice      BYTE ">> Please enter your choice (1-6): ", 0

; ======== User Interaction Strings ========
strUserLoginSuccess BYTE " Login Successful! Welcome back.", 0
strUserLoginFail    BYTE " Invalid Username or Password.", 0
strPassChanged      BYTE " Password changed successfully.", 0
strRelogin          BYTE " Please log in again with new credentials.", 0
strEnterNewPass     BYTE "Enter New Password (max 19): ", 0
strEnterWithdraw    BYTE "Enter amount to withdraw: $ ", 0
strWithdrawSuccess  BYTE " Withdrawal successful. New Balance: $ ", 0
strInsufficient     BYTE " Error: Insufficient funds.", 0
strCurrentBal       BYTE "Current Balance: $ ", 0
strEnterDeposit     BYTE "Enter amount to deposit: $ ", 0
strDepositSuccess   BYTE " Deposit successful. New Balance: $ ", 0

; ======== Transfer Money Strings ========
strEnterRecipientID BYTE "Enter Recipient Account ID: ", 0
strEnterTransferAmt BYTE "Enter amount to transfer: $ ", 0
strTransferSuccess  BYTE " Transfer successful. New Balance: $ ", 0
strTransferSelf     BYTE " Error: Cannot transfer money to your own account.", 0
strTransferNotFound BYTE " Error: Recipient Account ID not found.", 0

; ======== Input Buffers========
inputBuffer     BYTE 20 DUP(0) ; General Buffer
userLoginName   BYTE 20 DUP(0) ; Specific buffer for login name
userLoginPass   BYTE 20 DUP(0) ; Specific buffer for login pass

; ======== Status Strings ========
strEnterName      BYTE "Enter Account Name (max 19): ", 0
strEnterPassword  BYTE "Enter Account Password (max 19): ", 0
strEnterBalance   BYTE "Enter Initial Balance: $ ", 0
strEnterID        BYTE "Enter Account ID (e.g., 1000): ", 0
strEnterNewName   BYTE "Enter New Account Name (max 19): ", 0
strEnterNewBalance BYTE "Enter New Account Balance: $ ", 0
strFullError      BYTE " Error: Account Table is full!", 0
strSuccess        BYTE " Account created successfully!", 0
strEditSuccess    BYTE " Account Name updated successfully!", 0
strBalanceSuccess BYTE " Account Balance updated successfully!", 0
strInvalidIndex   BYTE " Error: Invalid Index or Empty Slot.", 0
strInvalidInput   BYTE " Invalid choice, please try again.", 0
strConfirmDelete  BYTE "Confirm delete (1=Yes, 0=No): ", 0
strDeleteSuccess  BYTE " Account deleted successfully.", 0
strDeleteCanceled BYTE " Deletion cancelled.", 0
strAcctNotFound   BYTE " Error: Account ID not found.", 0

; ======== Output Labels ========
accTitle          BYTE "---------- ACCOUNT DETAILS ----------", 0
accNameLabel      BYTE "Account Name: ", 0
accIDLabel        BYTE "Account ID: ", 0
accBalanceLabel   BYTE "Balance: $ ", 0
allAcctsHeading   BYTE "---------- ALL ACTIVE ACCOUNTS ----------", 0

.code
;---------------------------------------------------------
; FindAccountIndex
;---------------------------------------------------------
FindAccountIndex PROC USES ecx esi, targetID:DWORD
    mov ecx, CurrentAccountCount
    cmp ecx, 0
    je NotFound

    mov esi, OFFSET ACCOUNT_TABLE
    mov eax, 0 ; Index counter

FindLoop:
    mov ebx, (Account PTR [esi]).accountID
    cmp ebx, targetID
    je FoundIndex

    add esi, ACCOUNT_SIZE
    inc eax
    loop FindLoop

NotFound:
    mov eax, -1
    ret

FoundIndex:
    ret
FindAccountIndex ENDP

;---------------------------------------------------------
; InsertAccount
;---------------------------------------------------------
InsertAccount PROC USES eax ebx ecx edx esi
    mov eax, CurrentAccountCount
    cmp eax, MAX_ACCOUNTS
    jge ShowFullError

    mov esi, OFFSET ACCOUNT_TABLE
    mov eax, CurrentAccountCount
    mov ebx, SIZEOF Account
    mul ebx
    add esi, eax

    mov eax, 0Eh
    call SetTextColor
    mov edx, OFFSET strEnterName
    call WriteString
    mov eax, 07h
    call SetTextColor
    mov edx, esi
    mov ecx, SIZEOF Account.accountName
    call ReadString

    mov eax, 0Eh
    call SetTextColor
    mov edx, OFFSET strEnterPassword
    call WriteString
    mov eax, 07h
    call SetTextColor
    mov edx, esi
    add edx, SIZEOF Account.accountName
    mov ecx, SIZEOF Account.accountPassword
    call ReadString

    ; Set ID
    mov eax, NextAccountID
    mov (Account PTR [esi]).accountID, eax
    inc NextAccountID

    mov eax, 0Eh
    call SetTextColor
    mov edx, OFFSET strEnterBalance
    call WriteString
    mov eax, 07h
    call SetTextColor
    call ReadDec
    mov (Account PTR [esi]).accountBalance, eax

    inc CurrentAccountCount

    mov eax, 0Ah
    call SetTextColor
    call Crlf
    mov edx, OFFSET strSuccess
    call WriteString
    call Crlf
    jmp ExitInsert

ShowFullError:
    mov eax, 0Ch
    call SetTextColor
    mov edx, OFFSET strFullError
    call WriteString
    call Crlf

ExitInsert:
    mov eax, 07h 
    call SetTextColor
    ret
InsertAccount ENDP

;---------------------------------------------------------
; DisplayAccount
;---------------------------------------------------------
DisplayAccount PROC USES eax ebx edx esi, targetIndex:DWORD
    mov eax, targetIndex
    cmp eax, CurrentAccountCount
    jge InvalidIdx
    cmp eax, 0
    jl InvalidIdx

    mov esi, OFFSET ACCOUNT_TABLE
    mov eax, targetIndex
    mov ebx, SIZEOF Account
    mul ebx
    add esi, eax

    call Crlf

    mov eax, 0Bh
    call SetTextColor
    mov edx, OFFSET accTitle
    call WriteString
    call Crlf
    call Crlf

    mov eax, 07h
    call SetTextColor
    mov edx, OFFSET accNameLabel
    call WriteString
    mov eax, 0Eh
    call SetTextColor
    mov edx, esi
    call WriteString
    call Crlf

    mov eax, 07h
    call SetTextColor
    mov edx, OFFSET accIDLabel
    call WriteString
    mov eax, 0Eh
    call SetTextColor
    mov eax, (Account PTR [esi]).accountID
    call WriteDec
    call Crlf

    mov eax, 07h
    call SetTextColor
    mov edx, OFFSET accBalanceLabel
    call WriteString
    mov eax, 0Ah 
    call SetTextColor
    mov eax, (Account PTR [esi]).accountBalance
    call WriteDec
    call Crlf
    call Crlf
    jmp ExitDisplay

InvalidIdx:
    
    mov eax, 0Ch
    call SetTextColor
    mov edx, OFFSET strInvalidIndex
    call WriteString
    call Crlf

ExitDisplay:
    mov eax, 07h 
    call SetTextColor
    ret
DisplayAccount ENDP

;---------------------------------------------------------
; ViewAllAccounts
;---------------------------------------------------------
ViewAllAccounts PROC USES eax ebx ecx
    call Crlf
    
    mov eax, 0Bh
    call SetTextColor
    mov edx, OFFSET allAcctsHeading
    call WriteString
    call Crlf
    call Crlf

    mov ecx, CurrentAccountCount
    cmp ecx, 0
    je NoAccounts

    mov ebx, 0

ViewLoop:
    mov eax, ebx
    INVOKE DisplayAccount, eax 
    inc ebx
    loop ViewLoop
    jmp ExitView

NoAccounts:
    
    mov eax, 0Ch
    call SetTextColor
    mov edx, OFFSET strInvalidIndex
    call WriteString
    call Crlf

ExitView:
    mov eax, 07h 
    call SetTextColor
    ret
ViewAllAccounts ENDP

;---------------------------------------------------------
; Edit Procedures (Name and Balance)
;---------------------------------------------------------
EditAccountName PROC USES eax ebx ecx edx esi, targetIndex:DWORD
    mov esi, OFFSET ACCOUNT_TABLE
    mov eax, targetIndex
    mov ebx, SIZEOF Account
    mul ebx
    add esi, eax

    call Crlf
    
    mov eax, 0Eh
    call SetTextColor
    mov edx, OFFSET strEnterNewName
    call WriteString
    
    mov eax, 07h
    call SetTextColor
    mov edx, esi
    mov ecx, SIZEOF Account.accountName
    call ReadString

    
    mov eax, 0Ah
    call SetTextColor
    call Crlf
    mov edx, OFFSET strEditSuccess
    call WriteString
    call Crlf
    mov eax, 07h 
    call SetTextColor
    ret
EditAccountName ENDP

EditAccountBalance PROC USES eax ebx edx esi, targetIndex:DWORD
    mov esi, OFFSET ACCOUNT_TABLE
    mov eax, targetIndex
    mov ebx, SIZEOF Account
    mul ebx
    add esi, eax

    call Crlf
    
    mov eax, 0Eh
    call SetTextColor
    mov edx, OFFSET strEnterNewBalance
    call WriteString
   
    mov eax, 07h
    call SetTextColor
    call ReadDec
    mov (Account PTR [esi]).accountBalance, eax

    
    mov eax, 0Ah
    call SetTextColor
    call Crlf
    mov edx, OFFSET strBalanceSuccess
    call WriteString
    call Crlf
    mov eax, 07h 
    call SetTextColor
    ret
EditAccountBalance ENDP

;---------------------------------------------------------
; ChangeUserPassword
;---------------------------------------------------------
ChangeUserPassword PROC USES eax ebx ecx edx esi, targetIndex:DWORD
    mov esi, OFFSET ACCOUNT_TABLE
    mov eax, targetIndex
    mov ebx, SIZEOF Account
    mul ebx
    add esi, eax

    call Crlf
    
    mov eax, 0Eh
    call SetTextColor
    mov edx, OFFSET strEnterNewPass
    call WriteString

   
    mov eax, 07h
    call SetTextColor
    add esi, SIZEOF Account.accountName
    mov edx, esi
    mov ecx, SIZEOF Account.accountPassword
    call ReadString

    mov eax, 0Ah
    call SetTextColor
    call Crlf
    mov edx, OFFSET strPassChanged
    call WriteString
    call Crlf
    mov edx, OFFSET strRelogin
    call WriteString
    call Crlf
    mov eax, 07h 
    call SetTextColor
    ret
ChangeUserPassword ENDP

;---------------------------------------------------------
; WithdrawMoney
;---------------------------------------------------------
WithdrawMoney PROC USES eax ebx edx esi, targetIndex:DWORD
    ; 1. Calculate offset
    mov esi, OFFSET ACCOUNT_TABLE
    mov eax, targetIndex
    mov ebx, SIZEOF Account
    mul ebx
    add esi, eax

    ; 2. Display Current Balance
    call Crlf
    mov eax, 07h
    call SetTextColor
    mov edx, OFFSET strCurrentBal
    call WriteString
    mov eax, 0Ah
    call SetTextColor
    mov eax, (Account PTR [esi]).accountBalance
    call WriteDec
    call Crlf

    ; 3. Ask for withdrawal amount
    mov eax, 0Eh
    call SetTextColor
    mov edx, OFFSET strEnterWithdraw
    call WriteString
    mov eax, 07h
    call SetTextColor
    call ReadDec ; Value in EAX
    mov ebx, eax ; Save withdrawal amount in EBX

    ; 4. Check Funds
    mov eax, (Account PTR [esi]).accountBalance
    cmp eax, ebx
    jl InsufficientFunds ; Jump if Balance < Withdrawal

    ; 5. Subtract Funds
    sub eax, ebx
    mov (Account PTR [esi]).accountBalance, eax

    ; 6. Success Message
    call Crlf
    mov eax, 0Ah
    call SetTextColor
    mov edx, OFFSET strWithdrawSuccess
    call WriteString
    mov eax, (Account PTR [esi]).accountBalance ; Load new balance for display
    call WriteDec
    call Crlf
    jmp ExitWithdraw

InsufficientFunds:
    
    call Crlf
    mov eax, 0Ch
    call SetTextColor
    mov edx, OFFSET strInsufficient
    call WriteString
    call Crlf

ExitWithdraw:
    mov eax, 07h 
    call SetTextColor
    ret
WithdrawMoney ENDP

;---------------------------------------------------------
; DepositMoney
;---------------------------------------------------------
DepositMoney PROC USES eax ebx edx esi, targetIndex:DWORD
    ; 1. Calculate offset
    mov esi, OFFSET ACCOUNT_TABLE
    mov eax, targetIndex
    mov ebx, SIZEOF Account
    mul ebx
    add esi, eax

    ; 2. Display Current Balance
    call Crlf
    mov eax, 07h
    call SetTextColor
    mov edx, OFFSET strCurrentBal
    call WriteString
    mov eax, 0Ah
    call SetTextColor
    mov eax, (Account PTR [esi]).accountBalance
    call WriteDec
    call Crlf

    ; 3. Ask for deposit amount
    mov eax, 0Eh
    call SetTextColor
    mov edx, OFFSET strEnterDeposit
    call WriteString
    mov eax, 07h
    call SetTextColor
    call ReadDec ; Value in EAX (deposit amount)
    mov ebx, eax ; Save deposit amount in EBX

    ; 4. Add Funds
    mov eax, (Account PTR [esi]).accountBalance
    add eax, ebx
    mov (Account PTR [esi]).accountBalance, eax

    ; 5. Success Message
    call Crlf
    mov eax, 0Ah
    call SetTextColor
    mov edx, OFFSET strDepositSuccess
    call WriteString
    mov eax, (Account PTR [esi]).accountBalance ; Load new balance for display
    call WriteDec
    call Crlf

    mov eax, 07h 
    call SetTextColor
    ret
DepositMoney ENDP

;---------------------------------------------------------
; TransferMoney
;---------------------------------------------------------
TransferMoney PROC USES eax ebx ecx edx esi edi, senderIndex:DWORD
    LOCAL recipientID:DWORD
    LOCAL transferAmount:DWORD

    ; 1. Get Sender's ESI and ID
    mov esi, OFFSET ACCOUNT_TABLE
    mov eax, senderIndex
    mov ebx, SIZEOF Account
    mul ebx
    add esi, eax
    mov ecx, (Account PTR [esi]).accountID ; Save sender's ID in ECX

    ; 2. Display Current Balance 
    call Crlf
    mov eax, 07h
    call SetTextColor
    mov edx, OFFSET strCurrentBal
    call WriteString
    mov eax, 0Ah
    call SetTextColor
    mov eax, (Account PTR [esi]).accountBalance
    call WriteDec
    call Crlf
    mov eax, 07h
    call SetTextColor

    ; 3. Get Recipient ID
    mov eax, 0Eh
    call SetTextColor
    mov edx, OFFSET strEnterRecipientID
    call WriteString
    mov eax, 07h
    call SetTextColor
    call ReadDec
    mov recipientID, eax ; Save recipient ID

    ; 4. Check for self-transfer
    cmp eax, ecx
    je TransferSelfError

    ; 5. Find Recipient Index
    INVOKE FindAccountIndex, recipientID
    mov ebx, eax ; EBX = Recipient Index or -1
    cmp ebx, -1
    je TransferRecipientNotFound

    mov eax, 0Eh
    call SetTextColor
    mov edx, OFFSET strEnterTransferAmt
    call WriteString
    mov eax, 07h
    call SetTextColor
    call ReadDec
    mov transferAmount, eax ; Save transfer amount

    ; 7. Check Sender Funds
    mov eax, (Account PTR [esi]).accountBalance ; Sender's Balance
    cmp eax, transferAmount
    jl InsufficientFundsTransfer ; Jump if Balance < Transfer

    ; 8. Execute Transfer
    ; a. Deduct from Sender
    push eax
    mov eax, (Account PTR [esi]).accountBalance
    sub eax, transferAmount
    mov (Account PTR [esi]).accountBalance, eax
    pop eax

    ; b. Calculate Recipient ESI
    mov edi, OFFSET ACCOUNT_TABLE
    mov eax, ebx ; Recipient Index
    mov ecx, SIZEOF Account
    mul ecx
    add edi, eax ; EDI points to Recipient's Account struct

    ; c. Add to Recipient
    mov eax, (Account PTR [edi]).accountBalance
    add eax, transferAmount
    mov (Account PTR [edi]).accountBalance, eax

    ; 9. Success Message
    call Crlf
    mov eax, 0Ah
    call SetTextColor
    mov edx, OFFSET strTransferSuccess
    call WriteString
    mov eax, (Account PTR [esi]).accountBalance ; Load new balance for display
    call WriteDec
    call Crlf
    jmp ExitTransfer

TransferSelfError:
   
    call Crlf
    mov eax, 0Ch
    call SetTextColor
    mov edx, OFFSET strTransferSelf
    call WriteString
    call Crlf
    jmp ExitTransfer

TransferRecipientNotFound:
  
    call Crlf
    mov eax, 0Ch
    call SetTextColor
    mov edx, OFFSET strTransferNotFound
    call WriteString
    call Crlf
    jmp ExitTransfer

InsufficientFundsTransfer:
   
    call Crlf
    mov eax, 0Ch
    call SetTextColor
    mov edx, OFFSET strInsufficient
    call WriteString
    call Crlf

ExitTransfer:
    mov eax, 07h 
    call SetTextColor
    ret
TransferMoney ENDP


;---------------------------------------------------------
; DeleteAccount
;---------------------------------------------------------
DeleteAccount PROC USES eax ebx ecx esi edi, targetIndex:DWORD
    mov esi, OFFSET ACCOUNT_TABLE
    mov ebx, ACCOUNT_SIZE
    mov eax, targetIndex
    mul ebx
    add esi, eax

    mov edi, esi
    add esi, ACCOUNT_SIZE

    mov ecx, CurrentAccountCount
    sub ecx, targetIndex
    dec ecx
    cmp ecx, 0
    jle ShiftDone

    mov eax, ecx
    mov ebx, ACCOUNT_SIZE
    mul ebx
    mov ecx, eax
    shr ecx, 2
    cld
    rep movsd

ShiftDone:
    dec CurrentAccountCount
    dec NextAccountID

    ; Re-indexing IDs
    mov ecx, CurrentAccountCount
    sub ecx, targetIndex
    cmp ecx, 0
    jle ExitDelete

    mov eax, targetIndex
    mov ebx, ACCOUNT_SIZE
    mul ebx
    mov esi, OFFSET ACCOUNT_TABLE
    add esi, eax

    mov ebx, targetIndex

IdCorrectionLoop:
    mov eax, ebx
    add eax, ID_START
    mov (Account PTR [esi]).accountID, eax
    add esi, ACCOUNT_SIZE
    inc ebx
    loop IdCorrectionLoop

ExitDelete:
    ret
DeleteAccount ENDP

;---------------------------------------------------------
; UserMenu
;---------------------------------------------------------
UserMenu PROC USES eax edx, userIndex:DWORD

UserMenuLoop:
    call Clrscr
    
    mov eax, 0Bh
    call SetTextColor
    mov edx, OFFSET borderLine
    call WriteString
    call Crlf
    mov edx, OFFSET userMenuHeading
    call WriteString
    call Crlf
    mov edx, OFFSET borderLine
    call WriteString
    call Crlf

    ; Menu Options
    mov eax, 07h
    call SetTextColor
    mov edx, OFFSET menuBorder
    call WriteString
    call Crlf
    mov edx, OFFSET user1 ; 1. View Details
    call WriteString
    call Crlf
    mov edx, OFFSET user2 ; 2. Change Password
    call WriteString
    call Crlf
    mov edx, OFFSET user3 ; 3. Withdraw Money
    call WriteString
    call Crlf
    mov edx, OFFSET user4 ; 4. Deposit Money
    call WriteString
    call Crlf
    mov edx, OFFSET user5 ; 5. Transfer Money
    call WriteString
    call Crlf
    mov edx, OFFSET user6 ; 6. Logout
    call WriteString
    call Crlf

    ; Menu Border bottom
    mov eax, 0Bh
    call SetTextColor
    mov edx, OFFSET menuBorder
    call WriteString
    call Crlf

    ; Input Prompt 
    mov eax, 0Eh
    call SetTextColor
    mov edx, OFFSET userChoice
    call WriteString

    mov eax, 07h
    call SetTextColor
    call ReadInt

    cmp eax, 1
    je ChoiceUserDetails
    cmp eax, 2
    je ChoiceChangePass
    cmp eax, 3
    je ChoiceWithdraw
    cmp eax, 4
    je ChoiceDeposit
    cmp eax, 5
    je ChoiceTransfer
    cmp eax, 6
    je ChoiceLogout

    mov eax, 0Ch
    call SetTextColor
    mov edx, OFFSET strInvalidInput
    call WriteString
    call WaitMsg
    mov eax, 07h 
    call SetTextColor
    jmp UserMenuLoop

ChoiceUserDetails:
    call Crlf
    INVOKE DisplayAccount, userIndex
    call WaitMsg
    jmp UserMenuLoop

ChoiceChangePass:
    INVOKE ChangeUserPassword, userIndex
    call WaitMsg
    ret ; Force relogin

ChoiceWithdraw:
    INVOKE WithdrawMoney, userIndex
    call WaitMsg
    jmp UserMenuLoop

ChoiceDeposit:
    INVOKE DepositMoney, userIndex
    call WaitMsg
    jmp UserMenuLoop

ChoiceTransfer:
    INVOKE TransferMoney, userIndex
    call WaitMsg
    jmp UserMenuLoop

ChoiceLogout:
    ret ; Return to Login Screen
UserMenu ENDP

;---------------------------------------------------------
; UserLogin
;---------------------------------------------------------
UserLogin PROC USES eax ebx ecx edx esi edi
    call Crlf

    ; 1. Get Username 
    mov eax, 0Eh
    call SetTextColor
    mov edx, OFFSET strEnterName
    call WriteString
    mov eax, 07h
    call SetTextColor
    mov edx, OFFSET userLoginName
    mov ecx, SIZEOF userLoginName
    call ReadString

    ; 2. Get Password 
    mov eax, 0Eh
    call SetTextColor
    mov edx, OFFSET strEnterPassword
    call WriteString
    mov eax, 07h
    call SetTextColor
    mov edx, OFFSET userLoginPass
    mov ecx, SIZEOF userLoginPass
    call ReadString

    ; 3. Search Loop
    mov ecx, CurrentAccountCount
    cmp ecx, 0
    je LoginFail ; No accounts exist

    mov esi, OFFSET ACCOUNT_TABLE
    mov ebx, 0 ; Index counter

SearchLoop:
    ; A. Check Name
    INVOKE Str_compare, ADDR userLoginName, ADDR [esi].Account.accountName
    jne NextAccount ; If names don't match, skip to next

    ; B. Check Password (only if Name matched)
    mov edi, esi
    add edi, SIZEOF Account.accountName ; Move EDI to password field

    INVOKE Str_compare, ADDR userLoginPass, edi
    jne NextAccount ; If passwords don't match, skip to next

    ; C. Credentials Match
    jmp LoginSuccess

NextAccount:
    add esi, ACCOUNT_SIZE
    inc ebx
    loop SearchLoop

LoginFail:
    call Crlf
   
    mov eax, 0Ch
    call SetTextColor
    mov edx, OFFSET strUserLoginFail
    call WriteString
    call Crlf
    call WaitMsg
    mov eax, 07h 
    call SetTextColor
    ret

LoginSuccess:
    call Crlf
    
    mov eax, 0Ah
    call SetTextColor
    mov edx, OFFSET strUserLoginSuccess
    call WriteString
    call Crlf
    call WaitMsg
    mov eax, 07h 
    call SetTextColor

    ; Call the User Menu with the found index (EBX)
    INVOKE UserMenu, ebx
    ret
UserLogin ENDP

;---------------------------------------------------------
; AdminMenu
;---------------------------------------------------------
AdminMenu PROC

AdminMenuLoop:
    call Clrscr
    
    mov eax, 0Bh
    call SetTextColor
    mov edx, OFFSET borderLine
    call WriteString
    call Crlf
    mov edx, OFFSET adminMenuHeading
    call WriteString
    call Crlf
    mov edx, OFFSET borderLine
    call WriteString
    call Crlf

   
    mov eax, 07h
    call SetTextColor
    mov edx, OFFSET menuBorder
    call WriteString
    call Crlf
    mov edx, OFFSET admin1
    call WriteString
    call Crlf
    mov edx, OFFSET admin2
    call WriteString
    call Crlf
    mov edx, OFFSET admin3
    call WriteString
    call Crlf
    mov edx, OFFSET admin4
    call WriteString
    call Crlf
    mov edx, OFFSET admin5
    call WriteString
    call Crlf
    mov edx, OFFSET admin6
    call WriteString
    call Crlf
    mov edx, OFFSET admin7
    call WriteString
    call Crlf

    
    mov eax, 0Bh
    call SetTextColor
    mov edx, OFFSET menuBorder
    call WriteString
    call Crlf

    mov eax, 0Eh
    call SetTextColor
    mov edx, OFFSET adminChoice
    call WriteString
  
    mov eax, 07h
    call SetTextColor
    call ReadInt

    cmp eax, 1
    je ChoiceCreate
    cmp eax, 2
    je ChoiceDisplay
    cmp eax, 3
    je ChoiceViewAll
    cmp eax, 4
    je ChoiceDelete
    cmp eax, 5
    je ChoiceEditName
    cmp eax, 6
    je ChoiceEditBalance
    cmp eax, 7
    je ExitAdminMenu

    mov eax, 0Ch
    call SetTextColor
    mov edx, OFFSET strInvalidInput
    call WriteString
    call Crlf
    call WaitMsg
    mov eax, 07h 
    call SetTextColor
    jmp AdminMenuLoop

ChoiceCreate:
    call Crlf
    call InsertAccount 
    call WaitMsg
    jmp AdminMenuLoop

ChoiceDisplay:
    call Crlf
   
    mov eax, 0Eh
    call SetTextColor
    mov edx, OFFSET strEnterID
    call WriteString
    
    mov eax, 07h
    call SetTextColor
    call ReadDec
    mov ebx, eax
    INVOKE FindAccountIndex, ebx
    mov ebx, eax
    cmp ebx, -1
    je AdminDisplayNotFound

    INVOKE DisplayAccount, ebx 
    jmp AdminDisplayEnd

AdminDisplayNotFound:
   
    mov eax, 0Ch
    call SetTextColor
    mov edx, OFFSET strAcctNotFound
    call WriteString
    call Crlf

AdminDisplayEnd:
    call WaitMsg
    mov eax, 07h 
    call SetTextColor
    jmp AdminMenuLoop

ChoiceViewAll:
    call Crlf
    call ViewAllAccounts 
    call WaitMsg
    jmp AdminMenuLoop

ChoiceDelete:
    call Crlf
    
    mov eax, 0Eh
    call SetTextColor
    mov edx, OFFSET strEnterID
    call WriteString
    
    mov eax, 07h
    call SetTextColor
    call ReadDec
    mov ebx, eax
    INVOKE FindAccountIndex, ebx
    mov ebx, eax
    cmp ebx, -1
    je DeleteNotFoundAdmin

    
    mov eax, 0Eh
    call SetTextColor
    mov edx, OFFSET strConfirmDelete
    call WriteString
    
    mov eax, 07h
    call SetTextColor
    call ReadInt
    cmp eax, 1
    jne DeleteCanceledAdmin

    INVOKE DeleteAccount, ebx
    
    mov eax, 0Ah
    call SetTextColor
    mov edx, OFFSET strDeleteSuccess
    call WriteString
    call Crlf
    jmp DeleteEndAdmin

DeleteCanceledAdmin:
    
    mov eax, 07h
    call SetTextColor
    mov edx, OFFSET strDeleteCanceled
    call WriteString
    call Crlf
    jmp DeleteEndAdmin

DeleteNotFoundAdmin:
    
    mov eax, 0Ch
    call SetTextColor
    mov edx, OFFSET strAcctNotFound
    call WriteString
    call Crlf

DeleteEndAdmin:
    call WaitMsg
    mov eax, 07h 
    call SetTextColor
    jmp AdminMenuLoop

ChoiceEditName:
    call Crlf
   
    mov eax, 0Eh
    call SetTextColor
    mov edx, OFFSET strEnterID
    call WriteString
    
    mov eax, 07h
    call SetTextColor
    call ReadDec
    mov ebx, eax
    INVOKE FindAccountIndex, ebx
    mov ebx, eax
    cmp ebx, -1
    je EditNotFoundAdmin
    INVOKE EditAccountName, ebx
    jmp EditEndAdmin

ChoiceEditBalance:
    call Crlf
    
    mov eax, 0Eh
    call SetTextColor
    mov edx, OFFSET strEnterID
    call WriteString
    
    mov eax, 07h
    call SetTextColor
    call ReadDec
    mov ebx, eax
    INVOKE FindAccountIndex, ebx
    mov ebx, eax
    cmp ebx, -1
    je EditNotFoundAdmin
    INVOKE EditAccountBalance, ebx 
    jmp EditEndAdmin

EditNotFoundAdmin:
    
    mov eax, 0Ch
    call SetTextColor
    mov edx, OFFSET strAcctNotFound
    call WriteString
    call Crlf

EditEndAdmin:
    call WaitMsg
    mov eax, 07h 
    call SetTextColor
    jmp AdminMenuLoop

ExitAdminMenu:
    ret
AdminMenu ENDP


;---------------------------------------------------------
; Main Procedure
;---------------------------------------------------------
main PROC
    mov eax, 07h
    call SetTextColor

MainScreenLoop:
    call Clrscr

    mov eax, 0Bh
    call SetTextColor
    mov edx, OFFSET borderLine
    call WriteString
    call Crlf
    mov edx, OFFSET mainScreenHeading
    call WriteString
    call Crlf
    mov edx, OFFSET borderLine
    call WriteString
    call Crlf

    mov eax, 07h
    call SetTextColor
    mov edx, OFFSET menuBorder
    call WriteString
    call Crlf
    mov edx, OFFSET login1
    call WriteString
    call Crlf
    mov edx, OFFSET login2
    call WriteString
    call Crlf
    mov edx, OFFSET login3 
    call WriteString
    call Crlf
    mov edx, OFFSET login4 
    call WriteString
    call Crlf

    mov eax, 0Bh
    call SetTextColor
    mov edx, OFFSET menuBorder
    call WriteString
    call Crlf

    mov eax, 0Eh
    call SetTextColor
    mov edx, OFFSET loginChoice
    call WriteString

    mov eax, 07h
    call SetTextColor

    call ReadInt 	; EAX holds choice

    cmp eax, 1
    je ChoiceUserLogin
    cmp eax, 2
    je ChoiceAdminLogin
    cmp eax, 3
    je ChoiceCreateAccount
    cmp eax, 4
    je ChoiceExit

    mov eax, 0Ch
    call SetTextColor
    mov edx, OFFSET strInvalidInput
    call WriteString
    call Crlf
    call WaitMsg
    mov eax, 07h 
    call SetTextColor
    jmp MainScreenLoop

ChoiceUserLogin:
    call UserLogin 
    jmp MainScreenLoop

ChoiceCreateAccount:
    call Crlf
    call InsertAccount 
    call WaitMsg
    jmp MainScreenLoop

ChoiceAdminLogin:
    call Crlf

    mov eax, 0Eh
    call SetTextColor
    mov edx, OFFSET strEnterAdminPass
    call WriteString

    mov eax, 07h
    call SetTextColor

    mov edx, OFFSET inputBuffer
    mov ecx, SIZEOF inputBuffer
    call ReadString

    inc eax
    mov ecx, eax

    mov esi, OFFSET inputBuffer
    mov edi, OFFSET ADMIN_PASSWORD
    cld
    repe cmpsb

    je AdminLoginSuccess

    mov eax, 0Ch
    call SetTextColor
    mov edx, OFFSET strAdminFail
    call WriteString
    call Crlf
    call WaitMsg
    mov eax, 07h  
    call SetTextColor
    jmp MainScreenLoop

AdminLoginSuccess:
    
    mov eax, 0Ah
    call SetTextColor
    mov edx, OFFSET strAdminSuccess
    call WriteString
    call Crlf
    call WaitMsg
    mov eax, 07h 
    call SetTextColor

    call AdminMenu
    jmp MainScreenLoop

ChoiceExit:
    exit
main ENDP
END main
