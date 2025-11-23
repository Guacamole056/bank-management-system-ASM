; ============================================================
; Bank Management System - x86 Assembly
; File I/O excluded for simplicity
; ============================================================

INCLUDE Irvine32.inc

; Constants
MAX_USERS = 100
USERNAME_LENGTH = 30
PASSWORD_LENGTH = 30
MAX_ACCOUNTS = 100
ACCOUNT_STRUCT_SIZE = 4 + 50 + 4 + 4 + 30  ; accountNumber + name + balance + loyaltyPoints + ownerUsername
USER_STRUCT_SIZE = 30 + 30 + 4  ; username + password + isAdmin

.data
; User structure: username[30], password[30], isAdmin[4]
users BYTE MAX_USERS * USER_STRUCT_SIZE DUP(0)

; Account structure: accountNumber[4], name[50], balance[4], loyaltyPoints[4], ownerUsername[30]
accounts BYTE MAX_ACCOUNTS * ACCOUNT_STRUCT_SIZE DUP(0)

userCount DWORD 0
accountCount DWORD 0
nextAccountNumber DWORD 1000

; Current logged in user info
currentUsername BYTE USERNAME_LENGTH DUP(0)
currentIsAdmin DWORD 0

; String constants
strMainMenu BYTE "=================================", 0Ah, 0Dh
            BYTE "         Main Menu", 0Ah, 0Dh
            BYTE "=================================", 0Ah, 0Dh
            BYTE "1. Login", 0Ah, 0Dh
            BYTE "2. Create New Account", 0Ah, 0Dh
            BYTE "3. Exit", 0Ah, 0Dh
            BYTE "=================================", 0Ah, 0Dh
            BYTE "Enter your choice: ", 0

strAdminMenu BYTE "=================================", 0Ah, 0Dh
             BYTE "         Admin Menu", 0Ah, 0Dh
             BYTE "=================================", 0Ah, 0Dh
             BYTE "1. Add New Account", 0Ah, 0Dh
             BYTE "2. View All Accounts", 0Ah, 0Dh
             BYTE "3. View Account Details", 0Ah, 0Dh
             BYTE "4. Edit Account", 0Ah, 0Dh
             BYTE "5. Delete Account", 0Ah, 0Dh
             BYTE "6. Debit Account", 0Ah, 0Dh
             BYTE "7. Credit Account", 0Ah, 0Dh
             BYTE "8. Show All Users", 0Ah, 0Dh
             BYTE "9. Logout", 0Ah, 0Dh
             BYTE "=================================", 0Ah, 0Dh
             BYTE "Enter your choice: ", 0

strUserMenu BYTE "=================================", 0Ah, 0Dh
            BYTE "         User Menu", 0Ah, 0Dh
            BYTE "=================================", 0Ah, 0Dh
            BYTE "1. View Account Balance", 0Ah, 0Dh
            BYTE "2. Transfer Funds", 0Ah, 0Dh
            BYTE "3. Logout", 0Ah, 0Dh
            BYTE "=================================", 0Ah, 0Dh
            BYTE "Enter your choice: ", 0

strLogin BYTE "-----------------------------", 0Ah, 0Dh
         BYTE "         Login", 0Ah, 0Dh
         BYTE "-----------------------------", 0Ah, 0Dh, 0

strCreateAccount BYTE "-----------------------------", 0Ah, 0Dh
                  BYTE "      Create Account", 0Ah, 0Dh
                  BYTE "-----------------------------", 0Ah, 0Dh, 0

strAddAccount BYTE "-----------------------------", 0Ah, 0Dh
              BYTE "      Add New Account", 0Ah, 0Dh
              BYTE "-----------------------------", 0Ah, 0Dh, 0

strEnterUsername BYTE "Enter username: ", 0
strEnterPassword BYTE "Enter password: ", 0
strEnterName BYTE "Enter account holder name: ", 0
strEnterDeposit BYTE "Enter initial deposit: $", 0
strEnterAccountNum BYTE "Enter account number: ", 0
strEnterAmount BYTE "Enter amount: $", 0
strEnterSender BYTE "Enter sender account number: ", 0
strEnterReceiver BYTE "Enter receiver account number: ", 0

strLoginSuccess BYTE "Login successful! Welcome, ", 0
strLoginFail BYTE "Invalid username or password.", 0Ah, 0Dh, 0
strAccountCreated BYTE "Account created successfully!", 0Ah, 0Dh, 0
strUsernameExists BYTE "Username already exists.", 0Ah, 0Dh, 0
strInvalidChoice BYTE "Invalid choice.", 0Ah, 0Dh, 0
strLoggingOut BYTE "Logging out...", 0Ah, 0Dh, 0
strExiting BYTE "Exiting system...", 0Ah, 0Dh, 0
strNoAccounts BYTE "No accounts found.", 0Ah, 0Dh, 0
strNoUsers BYTE "No users found.", 0Ah, 0Dh, 0
strAccountNotFound BYTE "Account not found.", 0Ah, 0Dh, 0
strUserNotFound BYTE "User not found.", 0Ah, 0Dh, 0
strInsufficientBalance BYTE "Insufficient balance.", 0Ah, 0Dh, 0
strInvalidAmount BYTE "Invalid amount.", 0Ah, 0Dh, 0
strTransferSuccess BYTE "Transfer successful!", 0Ah, 0Dh, 0
strDebitSuccess BYTE "Amount debited successfully.", 0Ah, 0Dh, 0
strCreditSuccess BYTE "Amount credited successfully.", 0Ah, 0Dh, 0
strAccountDeleted BYTE "Account deleted successfully.", 0Ah, 0Dh, 0
strAccountUpdated BYTE "Account updated.", 0Ah, 0Dh, 0
strMaxUsers BYTE "Maximum users reached.", 0Ah, 0Dh, 0
strMaxAccounts BYTE "Maximum accounts reached.", 0Ah, 0Dh, 0

strAccountNum BYTE "Account Number: ", 0
strName BYTE "Name: ", 0
strBalance BYTE "Balance: $", 0
strLoyaltyPoints BYTE "Loyalty Points: ", 0
strOwner BYTE "Owner: ", 0
strUsername BYTE "Username: ", 0
strHasAccount BYTE "Has Account: ", 0
strYes BYTE "Yes", 0Ah, 0Dh, 0
strNo BYTE "No", 0Ah, 0Dh, 0

; Input buffers
tempUsername BYTE USERNAME_LENGTH DUP(0)
tempPassword BYTE PASSWORD_LENGTH DUP(0)
tempName BYTE 50 DUP(0)
tempBuffer BYTE 100 DUP(0)

.code
main PROC
    ; Initialize with default admin user
    call InitializeDefaultAdmin
    
    ; Main program loop
    MainLoop:
        call Clrscr
        mov edx, OFFSET strMainMenu
        call WriteString
        
        call ReadInt
        call Crlf
        
        cmp eax, 1
        je DoLogin
        cmp eax, 2
        je DoCreateAccount
        cmp eax, 3
        je DoExit
        jmp InvalidMainChoice
        
    DoLogin:
        call Login
        jmp MainLoop
        
    DoCreateAccount:
        call CreateUserAccount
        jmp MainLoop
        
    DoExit:
        mov edx, OFFSET strExiting
        call WriteString
        call WaitMsg
        exit
        
    InvalidMainChoice:
        mov edx, OFFSET strInvalidChoice
        call WriteString
        call WaitMsg
        jmp MainLoop
        
main ENDP

; Initialize with default admin user (admin/admin)
InitializeDefaultAdmin PROC
    pushad
    
    ; Calculate offset for first user
    mov esi, OFFSET users
    
    ; Copy "admin" to username
    mov edi, esi
    mov BYTE PTR [edi], 'a'
    inc edi
    mov BYTE PTR [edi], 'd'
    inc edi
    mov BYTE PTR [edi], 'm'
    inc edi
    mov BYTE PTR [edi], 'i'
    inc edi
    mov BYTE PTR [edi], 'n'
    inc edi
    mov BYTE PTR [edi], 0
    
    ; Copy "admin" to password
    add esi, USERNAME_LENGTH
    mov edi, esi
    mov BYTE PTR [edi], 'a'
    inc edi
    mov BYTE PTR [edi], 'd'
    inc edi
    mov BYTE PTR [edi], 'm'
    inc edi
    mov BYTE PTR [edi], 'i'
    inc edi
    mov BYTE PTR [edi], 'n'
    inc edi
    mov BYTE PTR [edi], 0
    
    ; Set isAdmin to 1
    add esi, PASSWORD_LENGTH
    mov DWORD PTR [esi], 1
    
    mov userCount, 1
    
    popad
    ret
InitializeDefaultAdmin ENDP

; Create a new user account
CreateUserAccount PROC
    pushad
    
    call Clrscr
    mov edx, OFFSET strCreateAccount
    call WriteString
    call Crlf
    
    ; Check if max users reached
    mov eax, userCount
    cmp eax, MAX_USERS
    jl ContinueCreate
    mov edx, OFFSET strMaxUsers
    call WriteString
    call WaitMsg
    popad
    ret
    
    ContinueCreate:
    ; Get username
    mov edx, OFFSET strEnterUsername
    call WriteString
    mov edx, OFFSET tempUsername
    mov ecx, USERNAME_LENGTH
    call ReadString
    call Crlf
    
    ; Check if username exists
    call CheckUsernameExists
    cmp eax, 1
    je UsernameExists
    
    ; Get password
    mov edx, OFFSET strEnterPassword
    call WriteString
    mov edx, OFFSET tempPassword
    mov ecx, PASSWORD_LENGTH
    call ReadString
    call Crlf
    
    ; Add user to array
    call AddUserToArray
    
    mov edx, OFFSET strAccountCreated
    call WriteString
    call WaitMsg
    
    popad
    ret
    
    UsernameExists:
    mov edx, OFFSET strUsernameExists
    call WriteString
    call WaitMsg
    popad
    ret
CreateUserAccount ENDP

; Check if username exists (returns 1 if exists, 0 if not)
CheckUsernameExists PROC
    push esi
    push edi
    push ecx
    push ebx
    
    mov esi, OFFSET users
    mov ecx, userCount
    cmp ecx, 0
    je NotExists
    
    CheckLoop:
        mov edi, esi
        push esi
        push ecx
        call StrCompare
        pop ecx
        pop esi
        cmp eax, 1
        je Exists
        add esi, USER_STRUCT_SIZE
        loop CheckLoop
    
    NotExists:
    mov eax, 0
    jmp Done
    
    Exists:
    mov eax, 1
    
    Done:
    pop ebx
    pop ecx
    pop edi
    pop esi
    ret
CheckUsernameExists ENDP

; Compare strings: ESI (user array) with tempUsername
; Returns 1 if equal, 0 if not
StrCompare PROC
    push esi
    push edi
    push ecx
    push ebx
    
    mov edi, OFFSET tempUsername
    
    CompareLoop:
        mov al, [esi]
        mov bl, [edi]
        cmp al, bl
        jne NotEqual
        cmp al, 0
        je Equal
        inc esi
        inc edi
        jmp CompareLoop
    
    Equal:
    mov eax, 1
    jmp Done
    
    NotEqual:
    mov eax, 0
    
    Done:
    pop ebx
    pop ecx
    pop edi
    pop esi
    ret
StrCompare ENDP

; Add user to array
AddUserToArray PROC
    push esi
    push edi
    push ecx
    push eax
    
    ; Calculate offset: userCount * USER_STRUCT_SIZE
    mov eax, userCount
    mov ebx, USER_STRUCT_SIZE
    mul ebx
    mov edi, OFFSET users
    add edi, eax
    
    ; Copy username
    mov esi, OFFSET tempUsername
    mov ecx, USERNAME_LENGTH
    rep movsb
    
    ; Copy password
    mov esi, OFFSET tempPassword
    mov ecx, PASSWORD_LENGTH
    rep movsb
    
    ; Set isAdmin to 0
    mov DWORD PTR [edi], 0
    
    ; Increment userCount
    inc userCount
    
    pop eax
    pop ecx
    pop edi
    pop esi
    ret
AddUserToArray ENDP

; Login procedure
Login PROC
    pushad
    
    call Clrscr
    mov edx, OFFSET strLogin
    call WriteString
    call Crlf
    
    ; Get username
    mov edx, OFFSET strEnterUsername
    call WriteString
    mov edx, OFFSET tempUsername
    mov ecx, USERNAME_LENGTH
    call ReadString
    call Crlf
    
    ; Get password
    mov edx, OFFSET strEnterPassword
    call WriteString
    mov edx, OFFSET tempPassword
    mov ecx, PASSWORD_LENGTH
    call ReadString
    call Crlf
    
    ; Verify credentials
    call VerifyLogin
    cmp eax, 1
    je LoginSuccess
    
    ; Login failed
    mov edx, OFFSET strLoginFail
    call WriteString
    call WaitMsg
    popad
    ret
    
    LoginSuccess:
    ; Store current user info
    mov esi, OFFSET tempUsername
    mov edi, OFFSET currentUsername
    mov ecx, USERNAME_LENGTH
    rep movsb
    
    mov edx, OFFSET strLoginSuccess
    call WriteString
    mov edx, OFFSET currentUsername
    call WriteString
    call Crlf
    call WaitMsg
    
    ; Check if admin or user
    cmp currentIsAdmin, 1
    je AdminLogin
    call UserMenu
    jmp LoginDone
    
    AdminLogin:
    call AdminMenu
    
    LoginDone:
    popad
    ret
Login ENDP

; Verify login credentials (returns 1 if valid, 0 if not)
VerifyLogin PROC
    push esi
    push edi
    push ecx
    push ebx
    push edx
    
    mov esi, OFFSET users
    mov ecx, userCount
    cmp ecx, 0
    je Invalid
    
    VerifyLoop:
        ; Check username
        push esi
        push ecx
        call StrCompare
        pop ecx
        pop esi
        cmp eax, 1
        jne NextUser
        
        ; Username matches, check password
        mov edi, esi
        add edi, USERNAME_LENGTH
        push esi
        push ecx
        call StrComparePassword
        pop ecx
        pop esi
        cmp eax, 1
        jne NextUser
        
        ; Both match, get isAdmin flag
        mov edi, esi
        add edi, USERNAME_LENGTH + PASSWORD_LENGTH
        mov eax, [edi]
        mov currentIsAdmin, eax
        mov eax, 1
        jmp Valid
        
        NextUser:
        add esi, USER_STRUCT_SIZE
        loop VerifyLoop
    
    Invalid:
    mov eax, 0
    
    Valid:
    pop edx
    pop ebx
    pop ecx
    pop edi
    pop esi
    ret
VerifyLogin ENDP

; Compare password: EDI (user array password) with tempPassword
StrComparePassword PROC
    push esi
    push edi
    push ecx
    push ebx
    
    mov esi, OFFSET tempPassword
    
    CompareLoop:
        mov al, [edi]
        mov bl, [esi]
        cmp al, bl
        jne NotEqual
        cmp al, 0
        je Equal
        inc esi
        inc edi
        jmp CompareLoop
    
    Equal:
    mov eax, 1
    jmp Done
    
    NotEqual:
    mov eax, 0
    
    Done:
    pop ebx
    pop ecx
    pop edi
    pop esi
    ret
StrComparePassword ENDP

; Admin Menu
AdminMenu PROC
    pushad
    
    AdminLoop:
        call Clrscr
        mov edx, OFFSET strAdminMenu
        call WriteString
        
        call ReadInt
        call Crlf
        
        cmp eax, 1
        je AdminAddAccount
        cmp eax, 2
        je AdminViewAccounts
        cmp eax, 3
        je AdminViewDetails
        cmp eax, 4
        je AdminEditAccount
        cmp eax, 5
        je AdminDeleteAccount
        cmp eax, 6
        je AdminDebit
        cmp eax, 7
        je AdminCredit
        cmp eax, 8
        je AdminShowUsers
        cmp eax, 9
        je AdminLogout
        jmp AdminInvalidChoice
        
        AdminAddAccount:
        call AddAccount
        jmp AdminLoop
        
        AdminViewAccounts:
        call ViewAccounts
        jmp AdminLoop
        
        AdminViewDetails:
        call ViewAccountDetails
        jmp AdminLoop
        
        AdminEditAccount:
        call EditAccount
        jmp AdminLoop
        
        AdminDeleteAccount:
        call DeleteAccount
        jmp AdminLoop
        
        AdminDebit:
        call DebitAccount
        jmp AdminLoop
        
        AdminCredit:
        call CreditAccount
        jmp AdminLoop
        
        AdminShowUsers:
        call ShowUsers
        jmp AdminLoop
        
        AdminLogout:
        mov edx, OFFSET strLoggingOut
        call WriteString
        call WaitMsg
        jmp AdminDone
        
        AdminInvalidChoice:
        mov edx, OFFSET strInvalidChoice
        call WriteString
        call WaitMsg
        jmp AdminLoop
        
    AdminDone:
    popad
    ret
AdminMenu ENDP

; User Menu
UserMenu PROC
    pushad
    
    UserLoop:
        call Clrscr
        mov edx, OFFSET strUserMenu
        call WriteString
        
        call ReadInt
        call Crlf
        
        cmp eax, 1
        je UserBalance
        cmp eax, 2
        je UserTransfer
        cmp eax, 3
        je UserLogout
        jmp UserInvalidChoice
        
        UserBalance:
        call BalanceInquiry
        jmp UserLoop
        
        UserTransfer:
        call FundTransfer
        jmp UserLoop
        
        UserLogout:
        mov edx, OFFSET strLoggingOut
        call WriteString
        call WaitMsg
        jmp UserDone
        
        UserInvalidChoice:
        mov edx, OFFSET strInvalidChoice
        call WriteString
        call WaitMsg
        jmp UserLoop
        
    UserDone:
    popad
    ret
UserMenu ENDP

; Add a new bank account (Admin only)
AddAccount PROC
    pushad
    
    ; Check if max accounts reached
    mov eax, accountCount
    cmp eax, MAX_ACCOUNTS
    jl ContinueAdd
    mov edx, OFFSET strMaxAccounts
    call WriteString
    call WaitMsg
    popad
    ret
    
    ContinueAdd:
    call Clrscr
    mov edx, OFFSET strAddAccount
    call WriteString
    call Crlf
    
    ; Get account owner username
    mov edx, OFFSET strEnterUsername
    call WriteString
    mov edx, OFFSET tempUsername
    mov ecx, USERNAME_LENGTH
    call ReadString
    call Crlf
    
    ; Verify user exists
    call CheckUsernameExists
    cmp eax, 0
    je UserNotFound
    
    ; Get account holder name
    mov edx, OFFSET strEnterName
    call WriteString
    mov edx, OFFSET tempName
    mov ecx, 50
    call ReadString
    call Crlf
    
    ; Get initial deposit
    mov edx, OFFSET strEnterDeposit
    call WriteString
    call ReadInt
    mov ebx, eax  ; Store deposit amount
    call Crlf
    
    ; Calculate offset for new account
    mov eax, accountCount
    mov ecx, ACCOUNT_STRUCT_SIZE
    mul ecx
    mov edi, OFFSET accounts
    add edi, eax
    
    ; Store account number
    mov eax, nextAccountNumber
    mov [edi], eax
    inc nextAccountNumber
    add edi, 4
    
    ; Store name
    mov esi, OFFSET tempName
    mov ecx, 50
    rep movsb
    
    ; Store balance
    mov [edi], ebx
    add edi, 4
    
    ; Calculate and store loyalty points (balance * 10 / 100)
    mov eax, ebx
    mov ecx, 10
    mul ecx
    mov ecx, 100
    div ecx
    mov [edi], eax
    add edi, 4
    
    ; Store owner username
    mov esi, OFFSET tempUsername
    mov ecx, USERNAME_LENGTH
    rep movsb
    
    inc accountCount
    
    mov edx, OFFSET strAccountCreated
    call WriteString
    call WaitMsg
    
    popad
    ret
    
    UserNotFound:
    mov edx, OFFSET strUserNotFound
    call WriteString
    call WaitMsg
    popad
    ret
AddAccount ENDP

; View all accounts
ViewAccounts PROC
    pushad
    
    call Clrscr
    mov eax, accountCount
    cmp eax, 0
    je NoAccounts
    
    ; Display accounts
    mov esi, OFFSET accounts
    mov ecx, accountCount
    
    DisplayLoop:
        push ecx
        push esi
        
        ; Display account number
        mov edx, OFFSET strAccountNum
        call WriteString
        mov eax, [esi]
        call WriteInt
        call Crlf
        
        ; Display name
        add esi, 4
        mov edx, OFFSET strName
        call WriteString
        mov edx, esi
        call WriteString
        call Crlf
        
        ; Display balance
        add esi, 50
        mov edx, OFFSET strBalance
        call WriteString
        mov eax, [esi]
        call WriteInt
        call Crlf
        
        ; Display loyalty points
        add esi, 4
        mov edx, OFFSET strLoyaltyPoints
        call WriteString
        mov eax, [esi]
        call WriteInt
        call Crlf
        
        call Crlf
        
        pop esi
        add esi, ACCOUNT_STRUCT_SIZE
        pop ecx
        loop DisplayLoop
    
    jmp ViewDone
    
    NoAccounts:
    mov edx, OFFSET strNoAccounts
    call WriteString
    
    ViewDone:
    call WaitMsg
    popad
    ret
ViewAccounts ENDP

; View account details
ViewAccountDetails PROC
    pushad
    
    call Clrscr
    mov edx, OFFSET strEnterAccountNum
    call WriteString
    call ReadInt
    mov ebx, eax  ; Store account number
    call Crlf
    
    ; Find account
    mov esi, OFFSET accounts
    mov ecx, accountCount
    
    FindLoop:
        cmp [esi], ebx
        je Found
        add esi, ACCOUNT_STRUCT_SIZE
        loop FindLoop
    
    ; Not found
    mov edx, OFFSET strAccountNotFound
    call WriteString
    call WaitMsg
    popad
    ret
    
    Found:
    ; Display account details
    mov edx, OFFSET strAccountNum
    call WriteString
    mov eax, [esi]
    call WriteInt
    call Crlf
    
    add esi, 4
    mov edx, OFFSET strName
    call WriteString
    mov edx, esi
    call WriteString
    call Crlf
    
    add esi, 50
    mov edx, OFFSET strBalance
    call WriteString
    mov eax, [esi]
    call WriteInt
    call Crlf
    
    add esi, 4
    mov edx, OFFSET strLoyaltyPoints
    call WriteString
    mov eax, [esi]
    call WriteInt
    call Crlf
    
    add esi, 4
    mov edx, OFFSET strOwner
    call WriteString
    mov edx, esi
    call WriteString
    call Crlf
    
    call WaitMsg
    popad
    ret
ViewAccountDetails ENDP

; Edit account
EditAccount PROC
    pushad
    
    call Clrscr
    mov edx, OFFSET strEnterAccountNum
    call WriteString
    call ReadInt
    mov ebx, eax
    call Crlf
    
    ; Find account
    mov esi, OFFSET accounts
    mov ecx, accountCount
    
    FindLoop:
        cmp [esi], ebx
        je Found
        add esi, ACCOUNT_STRUCT_SIZE
        loop FindLoop
    
    mov edx, OFFSET strAccountNotFound
    call WriteString
    call WaitMsg
    popad
    ret
    
    Found:
    ; Edit name
    add esi, 4
    mov edx, OFFSET strEnterName
    call WriteString
    mov edx, esi
    mov ecx, 50
    call ReadString
    call Crlf
    
    mov edx, OFFSET strAccountUpdated
    call WriteString
    call WaitMsg
    popad
    ret
EditAccount ENDP

; Delete account
DeleteAccount PROC
    pushad
    
    call Clrscr
    mov edx, OFFSET strEnterAccountNum
    call WriteString
    call ReadInt
    mov ebx, eax
    call Crlf
    
    ; Find account
    mov esi, OFFSET accounts
    mov ecx, accountCount
    mov edx, 0  ; Index counter
    
    FindLoop:
        cmp [esi], ebx
        je Found
        add esi, ACCOUNT_STRUCT_SIZE
        inc edx
        loop FindLoop
    
    mov edx, OFFSET strAccountNotFound
    call WriteString
    call WaitMsg
    popad
    ret
    
    Found:
    ; Shift accounts down
    mov edi, esi
    add esi, ACCOUNT_STRUCT_SIZE
    mov eax, accountCount
    sub eax, edx
    dec eax
    mov ecx, ACCOUNT_STRUCT_SIZE
    mul ecx
    mov ecx, eax
    rep movsb
    
    dec accountCount
    
    mov edx, OFFSET strAccountDeleted
    call WriteString
    call WaitMsg
    popad
    ret
DeleteAccount ENDP

; Debit account
DebitAccount PROC
    pushad
    
    call Clrscr
    mov edx, OFFSET strEnterAccountNum
    call WriteString
    call ReadInt
    mov ebx, eax  ; Account number
    call Crlf
    
    mov edx, OFFSET strEnterAmount
    call WriteString
    call ReadInt
    mov ecx, eax  ; Amount
    call Crlf
    
    cmp ecx, 0
    jle InvalidAmt
    
    ; Find account
    mov esi, OFFSET accounts
    mov edx, accountCount
    
    FindLoop:
        cmp [esi], ebx
        je Found
        add esi, ACCOUNT_STRUCT_SIZE
        dec edx
        jnz FindLoop
    
    mov edx, OFFSET strAccountNotFound
    call WriteString
    call WaitMsg
    popad
    ret
    
    Found:
    ; Check balance
    add esi, 54  ; Skip to balance
    mov eax, [esi]
    cmp eax, ecx
    jl Insufficient
    
    ; Debit
    sub eax, ecx
    mov [esi], eax
    
    ; Update loyalty points
    add esi, 4
    mov ebx, eax
    mov eax, ebx
    mov edx, 10
    mul edx
    mov edx, 100
    div edx
    mov [esi], eax
    
    mov edx, OFFSET strDebitSuccess
    call WriteString
    call WaitMsg
    popad
    ret
    
    Insufficient:
    mov edx, OFFSET strInsufficientBalance
    call WriteString
    call WaitMsg
    popad
    ret
    
    InvalidAmt:
    mov edx, OFFSET strInvalidAmount
    call WriteString
    call WaitMsg
    popad
    ret
DebitAccount ENDP

; Credit account
CreditAccount PROC
    pushad
    
    call Clrscr
    mov edx, OFFSET strEnterAccountNum
    call WriteString
    call ReadInt
    mov ebx, eax
    call Crlf
    
    mov edx, OFFSET strEnterAmount
    call WriteString
    call ReadInt
    mov ecx, eax
    call Crlf
    
    cmp ecx, 0
    jle InvalidAmt
    
    ; Find account
    mov esi, OFFSET accounts
    mov edx, accountCount
    
    FindLoop:
        cmp [esi], ebx
        je Found
        add esi, ACCOUNT_STRUCT_SIZE
        dec edx
        jnz FindLoop
    
    mov edx, OFFSET strAccountNotFound
    call WriteString
    call WaitMsg
    popad
    ret
    
    Found:
    ; Credit
    add esi, 54  ; Skip to balance
    mov eax, [esi]
    add eax, ecx
    mov [esi], eax
    
    ; Update loyalty points
    add esi, 4
    mov ebx, eax
    mov eax, ebx
    mov edx, 10
    mul edx
    mov edx, 100
    div edx
    mov [esi], eax
    
    mov edx, OFFSET strCreditSuccess
    call WriteString
    call WaitMsg
    popad
    ret
    
    InvalidAmt:
    mov edx, OFFSET strInvalidAmount
    call WriteString
    call WaitMsg
    popad
    ret
CreditAccount ENDP

; Fund transfer
FundTransfer PROC
    pushad
    
    call Clrscr
    mov edx, OFFSET strEnterSender
    call WriteString
    call ReadInt
    mov ebx, eax  ; Sender account
    call Crlf
    
    mov edx, OFFSET strEnterReceiver
    call WriteString
    call ReadInt
    mov edx, eax  ; Receiver account
    call Crlf
    
    mov edx, OFFSET strEnterAmount
    call WriteString
    call ReadInt
    mov ecx, eax  ; Amount
    call Crlf
    
    cmp ecx, 0
    jle InvalidAmt
    
    ; Find sender account
    mov esi, OFFSET accounts
    mov eax, accountCount
    mov edi, 0  ; Sender pointer
    mov ebp, 0  ; Receiver pointer
    
    FindSender:
        cmp [esi], ebx
        jne NextSender
        mov edi, esi
        jmp FindReceiver
        NextSender:
        add esi, ACCOUNT_STRUCT_SIZE
        dec eax
        jnz FindSender
    
    mov edx, OFFSET strAccountNotFound
    call WriteString
    call WaitMsg
    popad
    ret
    
    FindReceiver:
    mov esi, OFFSET accounts
    mov eax, accountCount
    
    FindRecv:
        cmp [esi], edx
        jne NextRecv
        mov ebp, esi
        jmp CheckBalance
        NextRecv:
        add esi, ACCOUNT_STRUCT_SIZE
        dec eax
        jnz FindRecv
    
    mov edx, OFFSET strAccountNotFound
    call WriteString
    call WaitMsg
    popad
    ret
    
    CheckBalance:
    ; Check sender balance
    mov esi, edi
    add esi, 54
    mov eax, [esi]
    cmp eax, ecx
    jl Insufficient
    
    ; Perform transfer
    sub eax, ecx
    mov [esi], eax
    
    ; Update sender loyalty points
    add esi, 4
    mov ebx, eax
    mov eax, ebx
    mov edx, 10
    mul edx
    mov edx, 100
    div edx
    mov [esi], eax
    
    ; Update receiver balance
    mov esi, ebp
    add esi, 54
    mov eax, [esi]
    add eax, ecx
    mov [esi], eax
    
    ; Update receiver loyalty points
    add esi, 4
    mov ebx, eax
    mov eax, ebx
    mov edx, 10
    mul edx
    mov edx, 100
    div edx
    mov [esi], eax
    
    mov edx, OFFSET strTransferSuccess
    call WriteString
    call WaitMsg
    popad
    ret
    
    Insufficient:
    mov edx, OFFSET strInsufficientBalance
    call WriteString
    call WaitMsg
    popad
    ret
    
    InvalidAmt:
    mov edx, OFFSET strInvalidAmount
    call WriteString
    call WaitMsg
    popad
    ret
FundTransfer ENDP

; Balance inquiry
BalanceInquiry PROC
    pushad
    
    call Clrscr
    mov esi, OFFSET accounts
    mov ecx, accountCount
    mov edi, OFFSET currentUsername
    mov ebx, 0  ; Found flag
    
    SearchLoop:
        push esi
        push edi
        add esi, 88  ; Skip to owner username
        mov edi, OFFSET currentUsername
        push ecx
        call StrCompareOwner
        pop ecx
        pop edi
        pop esi
        cmp eax, 1
        je DisplayAccount
        add esi, ACCOUNT_STRUCT_SIZE
        loop SearchLoop
    
    cmp ebx, 0
    jne Done
    mov edx, OFFSET strNoAccounts
    call WriteString
    
    Done:
    call WaitMsg
    popad
    ret
    
    DisplayAccount:
    mov ebx, 1
    push esi
    push ecx
    
    mov edx, OFFSET strAccountNum
    call WriteString
    mov eax, [esi]
    call WriteInt
    call Crlf
    
    add esi, 4
    mov edx, OFFSET strName
    call WriteString
    mov edx, esi
    call WriteString
    call Crlf
    
    add esi, 50
    mov edx, OFFSET strBalance
    call WriteString
    mov eax, [esi]
    call WriteInt
    call Crlf
    
    add esi, 4
    mov edx, OFFSET strLoyaltyPoints
    call WriteString
    mov eax, [esi]
    call WriteInt
    call Crlf
    call Crlf
    
    pop ecx
    pop esi
    add esi, ACCOUNT_STRUCT_SIZE
    dec ecx
    jz Done
    jmp SearchLoop
BalanceInquiry ENDP

; Compare owner username: ESI (tempBuffer or account owner) with EDI (currentUsername or tempBuffer)
; This is a generic string compare - caller sets up ESI and EDI
StrCompareOwner PROC
    push esi
    push edi
    push ecx
    push ebx
    
    CompareLoop:
        mov al, [esi]
        mov bl, [edi]
        cmp al, bl
        jne NotEqual
        cmp al, 0
        je Equal
        inc esi
        inc edi
        jmp CompareLoop
    
    Equal:
    mov eax, 1
    jmp Done
    
    NotEqual:
    mov eax, 0
    
    Done:
    pop ebx
    pop ecx
    pop edi
    pop esi
    ret
StrCompareOwner ENDP

; Show all users
ShowUsers PROC
    pushad
    
    call Clrscr
    mov eax, userCount
    cmp eax, 0
    je NoUsers
    
    mov esi, OFFSET users
    mov ecx, userCount
    
    ShowLoop:
        push ecx
        push esi
        
        mov edx, OFFSET strUsername
        call WriteString
        mov edx, esi
        call WriteString
        call Crlf
        
        ; Check for accounts (before modifying ESI)
        call CheckUserHasAccount
        cmp eax, 1
        je HasAcc
        mov edx, OFFSET strNo
        jmp ShowHasAccount
        HasAcc:
        mov edx, OFFSET strYes
        ShowHasAccount:
        mov eax, OFFSET strHasAccount
        call WriteString
        call WriteString
        call Crlf
        call Crlf
        
        pop esi
        add esi, USER_STRUCT_SIZE
        pop ecx
        loop ShowLoop
    
    jmp ShowDone
    
    NoUsers:
    mov edx, OFFSET strNoUsers
    call WriteString
    
    ShowDone:
    call WaitMsg
    popad
    ret
ShowUsers ENDP

; Check if user has account (ESI points to username in users array)
; Returns 1 if has account, 0 if not
CheckUserHasAccount PROC
    push esi
    push edi
    push ecx
    push ebx
    push edx
    
    ; Save username to temp buffer for comparison
    mov edi, OFFSET tempBuffer
    mov ecx, USERNAME_LENGTH
    rep movsb
    
    mov edi, OFFSET accounts
    mov ecx, accountCount
    cmp ecx, 0
    je NoAccount
    
    CheckLoop:
        push edi
        add edi, 88  ; Skip to owner username
        mov esi, OFFSET tempBuffer
        push ecx
        call StrCompareOwner
        pop ecx
        pop edi
        cmp eax, 1
        je HasAccount
        add edi, ACCOUNT_STRUCT_SIZE
        loop CheckLoop
    
    NoAccount:
    mov eax, 0
    jmp Done
    
    HasAccount:
    mov eax, 1
    
    Done:
    pop edx
    pop ebx
    pop ecx
    pop edi
    pop esi
    ret
CheckUserHasAccount ENDP

END main
