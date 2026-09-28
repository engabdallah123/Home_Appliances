using POS.Shared.Domain;

namespace Identity.Domain.Users
{
    public static class UserErrors
    {
        public static Error NotFound(string id) =>
            new("User.NotFound", $"المستخدم بالرقم '{id}' غير موجود.");

        public static readonly Error InvalidCredentials =
            new("User.InvalidCredentials", "بيانات الدخول غير صحيحة.");

        public static readonly Error UserInactive =
            new("User.Inactive", "حساب المستخدم غير مفعّل.");

        public static readonly Error DuplicateEmail =
            Error.Conflict("User.DuplicateEmail", "يوجد بالفعل مستخدم بنفس البريد الإلكتروني.");

        public static readonly Error DuplicateUserName =
            Error.Conflict("User.DuplicateUserName", "يوجد بالفعل مستخدم بنفس اسم المستخدم.");

        public static readonly Error RegistrationFailed =
            new("User.RegistrationFailed", "فشل في إنشاء حساب المستخدم.");

        public static readonly Error InvalidRefreshToken =
            new("User.InvalidRefreshToken", "رمز التحديث غير صالح أو منتهي الصلاحية.");

        public static readonly Error RoleAssignmentFailed =
            new("User.RoleAssignmentFailed", "فشل في تعيين الدور للمستخدم.");
    }
}
