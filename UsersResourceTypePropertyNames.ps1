$UsersPropertyNames = @"
Field Name
Inactive
Alias
DisplayName
FirstName
LastName
SmtpAddress
TimeZone
UseDefaultTimeZone
Language
UseDefaultLanguage
LdapType
LocationObjectId
IsTemplate
Initials
Title
EmployeeId
Address
Building
City
State
PostalCode
Country
Department
Manager
BillingId
EmailAddress
DtmfAccessId
XferString
FaxServerObjectId
PartitionObjectId
MediaSwitchObjectId
SearchByExtensionSearchSpaceObjectId
SearchByNameSearchSpaceObjectId
CosObjectId
CallHandlerObjectId
ScheduleSetObjectId
TenantObjectId
IsVmEnrolled
SkipPasswordForKnownDevice
ListInDirectory
UseShortPollForCache
RouteNDRToSender
Undeletable
VoiceName
DialablePhoneNumber
PhoneNumber
CreateSmtpProxyFromCorp
"@ -split "`r`n" 

$UsersPropertyNames | % { "`$$_,"}