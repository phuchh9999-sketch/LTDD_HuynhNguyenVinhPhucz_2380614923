using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using _2380614923_HuynhNguyenVinhPhuc_WebAPI.Data;
using _2380614923_HuynhNguyenVinhPhuc_WebAPI.Models;
using _2380614923_HuynhNguyenVinhPhuc_WebAPI.Services;

var builder = WebApplication.CreateBuilder(args);

// Đăng ký dịch vụ gửi Email OTP thực tế
builder.Services.AddScoped<IEmailService, EmailService>();

// 1. Cấu hình Database SQL Server với Database cá nhân: DB_2380614923_HuynhNguyenVinhPhuc
builder.Services.AddDbContext<KidGuardDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// 2. Cấu hình ASP.NET Core Identity
builder.Services.AddIdentity<User, IdentityRole>(options =>
{
    options.Password.RequireDigit = false;
    options.Password.RequireLowercase = false;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequireUppercase = false;
    options.Password.RequiredLength = 6;
    options.User.AllowedUserNameCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._@+ àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ";
})
.AddEntityFrameworkStores<KidGuardDbContext>()
.AddDefaultTokenProviders();

// Xóa validator kiểm tra ký tự mặc định của Identity để cho phép tiếng Việt và khoảng trắng
var userValidators = builder.Services.Where(s => s.ServiceType == typeof(IUserValidator<User>)).ToList();
foreach (var v in userValidators) builder.Services.Remove(v);
builder.Services.AddScoped<IUserValidator<User>, CustomUserValidator>();

// 3. Add Controllers with JsonOptions
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
    });

// 4. Configure CORS cho Flutter App và Mobile Emulators
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// 5. Configure JWT Authentication
var jwtSettings = builder.Configuration.GetSection("JWTKey");
var key = Encoding.UTF8.GetBytes(jwtSettings["Secret"]!);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSettings["ValidIssuer"],
        ValidAudience = jwtSettings["ValidAudience"],
        IssuerSigningKey = new SymmetricSecurityKey(key)
    };
});

builder.Services.AddAuthorization();

// 6. Cấu hình Swagger với giao diện Bearer JWT
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "2380614923_HuynhNguyenVinhPhuc_WebAPI - KidGuard System",
        Version = "v1",
        Description = "Hệ thống WebAPI Quản lý Điện thoại Trẻ em (KidGuard) - Sinh viên: Huỳnh Nguyễn Vĩnh Phúc - MSSV: 2380614923 - Nhóm: goddy"
    });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Nhập token JWT theo định dạng: Bearer {token}",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

// 7. Tự động khởi tạo Database và Seed dữ liệu mẫu đầy đủ
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<KidGuardDbContext>();
        context.Database.EnsureCreated();

        var roleManager = services.GetRequiredService<RoleManager<IdentityRole>>();
        var userManager = services.GetRequiredService<UserManager<User>>();

        // Seed 4 Roles: Admin, Staff, Parent, Child
        string[] roles = { "Admin", "Staff", "Parent", "Child" };
        foreach (var role in roles)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                await roleManager.CreateAsync(new IdentityRole(role));
            }
        }

        // 1. Chỉ giữ duy nhất 1 tài khoản Admin (tk: Admin, mk: admin123)
        var adminUser = await userManager.FindByNameAsync("Admin")
                     ?? await userManager.FindByNameAsync("admin");
        if (adminUser == null)
        {
            adminUser = new User
            {
                UserName = "Admin",
                Email = "admin@kidguard.com",
                FullName = "Quản Trị Viên Hệ Thống",
                Role = "Admin",
                Initials = "AD"
            };
            var res = await userManager.CreateAsync(adminUser, "admin123");
            if (res.Succeeded) await userManager.AddToRoleAsync(adminUser, "Admin");
        }
        else
        {
            adminUser.UserName = "Admin";
            adminUser.Role = "Admin";
            adminUser.FullName = "Quản Trị Viên Hệ Thống";
            await userManager.UpdateAsync(adminUser);

            var resetToken = await userManager.GeneratePasswordResetTokenAsync(adminUser);
            await userManager.ResetPasswordAsync(adminUser, resetToken, "admin123");
            if (!await userManager.IsInRoleAsync(adminUser, "Admin"))
            {
                await userManager.AddToRoleAsync(adminUser, "Admin");
            }
        }

        User? staffUser = null;
        User? parentUser = null;

        // Seed Devices nếu chưa có
        if (!context.ChildDevices.Any())
        {
            var device1 = new ChildDevice
            {
                DeviceName = "Samsung Galaxy A54 - Bé Nam",
                ModelName = "SM-A546E",
                OsVersion = "Android 14",
                DeviceCode = "KID-88662",
                ParentId = parentUser?.Id,
                ChildName = "Huỳnh Gia Nam (10 tuổi)",
                DailyScreenTimeLimitMinutes = 120,
                UsedScreenTimeMinutes = 45,
                IsLocked = false,
                BatteryLevel = 82,
                CurrentLatitude = 10.801889,
                CurrentLongitude = 106.711806,
                CurrentAddress = "Trường Tiểu Học Chu Văn An, Bình Thạnh, TP. HCM",
                CurrentNoiseLevel = 44.5,
                IsOnline = true,
                CreatedAt = DateTime.UtcNow
            };

            var device2 = new ChildDevice
            {
                DeviceName = "iPad Mini 6 - Bé Vy",
                ModelName = "iPad14,1",
                OsVersion = "iPadOS 17.5",
                DeviceCode = "KID-33921",
                ParentId = parentUser?.Id,
                ChildName = "Huỳnh Bảo Vy (7 tuổi)",
                DailyScreenTimeLimitMinutes = 90,
                UsedScreenTimeMinutes = 25,
                IsLocked = false,
                BatteryLevel = 95,
                CurrentLatitude = 10.776889,
                CurrentLongitude = 106.700806,
                CurrentAddress = "Nhà Riêng, Quận 1, TP. Hồ Chí Minh",
                CurrentNoiseLevel = 38.0,
                IsOnline = true,
                CreatedAt = DateTime.UtcNow
            };

            context.ChildDevices.AddRange(device1, device2);
            await context.SaveChangesAsync();

            // Seed App Restrictions
            context.AppRestrictions.AddRange(
                new AppRestriction { ChildDeviceId = device1.Id, AppName = "TikTok", PackageName = "com.ss.android.ugc.trill", Category = "Mạng xã hội", DailyLimitMinutes = 20, IsBlocked = false },
                new AppRestriction { ChildDeviceId = device1.Id, AppName = "YouTube Kids", PackageName = "com.google.android.apps.youtube.kids", Category = "Giải trí", DailyLimitMinutes = 45, IsBlocked = false },
                new AppRestriction { ChildDeviceId = device1.Id, AppName = "Roblox", PackageName = "com.roblox.client", Category = "Trò chơi", DailyLimitMinutes = 30, IsBlocked = false },
                new AppRestriction { ChildDeviceId = device1.Id, AppName = "Facebook", PackageName = "com.facebook.katana", Category = "Mạng xã hội", DailyLimitMinutes = 0, IsBlocked = true },
                new AppRestriction { ChildDeviceId = device2.Id, AppName = "Duolingo", PackageName = "com.duolingo", Category = "Học tập", DailyLimitMinutes = 60, IsBlocked = false },
                new AppRestriction { ChildDeviceId = device2.Id, AppName = "YouTube", PackageName = "com.google.android.youtube", Category = "Giải trí", DailyLimitMinutes = 0, IsBlocked = true }
            );

            // Seed Safe Zones
            context.SafeZones.AddRange(
                new SafeZone
                {
                    ChildDeviceId = device1.Id,
                    ParentId = parentUser?.Id,
                    Name = "Trường Chu Văn An",
                    Address = "Đinh Tiên Hoàng, Phường 1, Bình Thạnh",
                    Latitude = 10.801889,
                    Longitude = 106.711806,
                    RadiusMeters = 300
                },
                new SafeZone
                {
                    ChildDeviceId = device1.Id,
                    ParentId = parentUser?.Id,
                    Name = "Nhà Riêng",
                    Address = "Nguyễn Hữu Cảnh, Quận 1, TP. HCM",
                    Latitude = 10.776889,
                    Longitude = 106.700806,
                    RadiusMeters = 250
                }
            );

            // Seed Security Alerts
            context.SecurityAlerts.AddRange(
                new SecurityAlert
                {
                    ChildDeviceId = device1.Id,
                    ChildName = device1.ChildName,
                    AlertType = "HIGH_NOISE_BULLYING",
                    Title = "Cảnh báo tiếng ồn lớn & Nguy cơ bắt nạt",
                    Description = "Micro phát hiện cường độ âm thanh đạt 89.2 dB vượt ngưỡng an toàn trong 15 giây liên tục!",
                    Latitude = 10.801889,
                    Longitude = 106.711806,
                    NoiseDecibel = 89.2,
                    Severity = "High",
                    IsResolved = false,
                    CreatedAt = DateTime.UtcNow.AddMinutes(-25)
                },
                new SecurityAlert
                {
                    ChildDeviceId = device1.Id,
                    ChildName = device1.ChildName,
                    AlertType = "FALL_SHAKE_IMPACT",
                    Title = "Phát hiện gia tốc va chạm mạnh / Rơi máy",
                    Description = "Cảm biến chuyển động đo được rung lắc gia tốc 26.8 m/s² bất thường.",
                    Latitude = 10.801889,
                    Longitude = 106.711806,
                    NoiseDecibel = 55.0,
                    Severity = "Medium",
                    IsResolved = true,
                    CreatedAt = DateTime.UtcNow.AddHours(-3)
                }
            );

            // Seed Habit Quests
            context.HabitQuests.AddRange(
                new HabitQuest
                {
                    ChildDeviceId = device1.Id,
                    Title = "Đọc sách truyện 30 phút",
                    Description = "Đọc ít nhất 1 chương sách văn học hoặc khoa học",
                    RewardMinutes = 30,
                    IsCompleted = true,
                    IsApproved = false,
                    CreatedAt = DateTime.UtcNow.AddHours(-2)
                },
                new HabitQuest
                {
                    ChildDeviceId = device1.Id,
                    Title = "Hoàn thành bài tập toán về nhà",
                    Description = "Làm hết bài tập đại số trang 45",
                    RewardMinutes = 45,
                    IsCompleted = false,
                    IsApproved = false,
                    ModerationStatus = "Approved",
                    StaffNotes = "Nhiệm vụ rèn luyện tốt",
                    CreatedAt = DateTime.UtcNow.AddHours(-1)
                }
            );

            // Seed Parent Audit Logs
            if (parentUser != null)
            {
                context.ParentAuditLogs.AddRange(
                    new ParentAuditLog
                    {
                        ParentId = parentUser.Id,
                        ParentName = parentUser.FullName,
                        ActionType = "ADD_DEVICE",
                        TargetName = device1.DeviceName,
                        Details = $"Thêm thiết bị con trẻ: {device1.DeviceName} ({device1.ModelName})",
                        CreatedAt = DateTime.UtcNow.AddDays(-3)
                    },
                    new ParentAuditLog
                    {
                        ParentId = parentUser.Id,
                        ParentName = parentUser.FullName,
                        ActionType = "ADD_SAFE_ZONE",
                        TargetName = "Trường Chu Văn An",
                        Details = "Thiết lập vùng an toàn bán kính 300m quanh trường học",
                        CreatedAt = DateTime.UtcNow.AddDays(-2)
                    },
                    new ParentAuditLog
                    {
                        ParentId = parentUser.Id,
                        ParentName = parentUser.FullName,
                        ActionType = "LOCK_DEVICE",
                        TargetName = device1.DeviceName,
                        Details = "Khóa màn hình máy bé Nam lúc 22:00 để đi ngủ",
                        CreatedAt = DateTime.UtcNow.AddHours(-12)
                    },
                    new ParentAuditLog
                    {
                        ParentId = parentUser.Id,
                        ParentName = parentUser.FullName,
                        ActionType = "UNLOCK_DEVICE",
                        TargetName = device1.DeviceName,
                        Details = "Mở khóa màn hình máy bé Nam lúc 06:30 sáng",
                        CreatedAt = DateTime.UtcNow.AddHours(-4)
                    }
                );

                // Seed Staff Incident Reports to Admin
                context.StaffIncidentReports.AddRange(
                    new StaffIncidentReport
                    {
                        StaffId = staffUser?.Id ?? "staff_default",
                        StaffName = staffUser?.FullName ?? "Nguyễn Văn Tuấn (Kỹ Thuật Viên)",
                        ParentId = parentUser.Id,
                        ParentName = parentUser.FullName,
                        ChildDeviceId = device1.Id,
                        ChildName = device1.ChildName,
                        Title = "Cảnh báo tiếng ồn cao bất thường kéo dài",
                        Reason = "Cảm biến micro ghi nhận cường độ âm thanh 89.2 dB vượt ngưỡng trong hơn 15 phút. Nhân viên đã kiểm tra và ghi nhận nghi vấn có hiện tượng tranh cãi hoặc bắt nạt học đường, đề xuất Admin gửi thông báo nhắc nhở phụ huynh.",
                        Severity = "Critical",
                        Status = "Pending",
                        CreatedAt = DateTime.UtcNow.AddMinutes(-35)
                    }
                );

                // Seed Admin Warning to Parent
                context.AdminWarnings.AddRange(
                    new AdminWarning
                    {
                        ParentId = parentUser.Id,
                        ParentName = parentUser.FullName,
                        AdminId = adminUser?.Id,
                        AdminName = adminUser?.FullName ?? "Quản Trị Viên Hệ Thống",
                        Title = "Nhắc nhở kiểm tra an toàn âm thanh xung quanh bé Nam",
                        Message = "Hệ thống và Đội ngũ Giám sát Kỹ thuật ghi nhận cảnh báo mức âm thanh 89.2 dB vượt ngưỡng an toàn tại Trường Chu Văn An. Đề nghị phụ huynh liên hệ với nhà trường hoặc kiểm tra trực tiếp tình trạng của bé.",
                        Severity = "Warning",
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow.AddMinutes(-20)
                    }
                );
            }

            await context.SaveChangesAsync();
        }
    }
    catch (Exception ex)
    {
        var logger = services.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "Lỗi xảy ra trong quá trình khởi tạo dữ liệu Database.");
    }
}

// 8. Middleware Pipeline
if (app.Environment.IsDevelopment() || true)
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "2380614923_HuynhNguyenVinhPhuc_WebAPI v1");
    });
}

app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();

public class CustomUserValidator : IUserValidator<User>
{
    public Task<IdentityResult> ValidateAsync(UserManager<User> manager, User user)
    {
        if (string.IsNullOrWhiteSpace(user.UserName))
        {
            return Task.FromResult(IdentityResult.Failed(new IdentityError
            {
                Code = "InvalidUserName",
                Description = "Tên đăng nhập không được để trống"
            }));
        }
        return Task.FromResult(IdentityResult.Success);
    }
}

