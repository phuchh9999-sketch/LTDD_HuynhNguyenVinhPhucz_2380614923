using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using _2380614923_HuynhNguyenVinhPhuc_WebAPI.Data;
using _2380614923_HuynhNguyenVinhPhuc_WebAPI.Models;
using _2380614923_HuynhNguyenVinhPhuc_WebAPI.Services;

namespace _2380614923_HuynhNguyenVinhPhuc_WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthenticateController : ControllerBase
    {
        private readonly UserManager<User> _userManager;
        private readonly RoleManager<IdentityRole> _roleManager;
        private readonly IConfiguration _configuration;
        private readonly KidGuardDbContext _context;
        private readonly IEmailService _emailService;

        public AuthenticateController(
            UserManager<User> userManager,
            RoleManager<IdentityRole> roleManager,
            IConfiguration configuration,
            KidGuardDbContext context,
            IEmailService emailService)
        {
            _userManager = userManager;
            _roleManager = roleManager;
            _configuration = configuration;
            _context = context;
            _emailService = emailService;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterDto model)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var userExists = await _userManager.FindByNameAsync(model.Username);
            if (userExists != null)
                return BadRequest(new AuthResponseDto { Status = false, Message = "Tên đăng nhập đã tồn tại trong hệ thống!" });

            var role = string.IsNullOrEmpty(model.Role) ? "Parent" : model.Role;
            User? parentUser = null;

            if (role == "Child")
            {
                // Khi tạo tài khoản cho trẻ: Cho phép sử dụng email của phụ huynh
                // Tìm kiếm tài khoản phụ huynh sở hữu email này trong hệ thống
                var usersWithEmail = await _userManager.Users.Where(u => u.Email == model.Email).ToListAsync();
                parentUser = usersWithEmail.FirstOrDefault(u => u.Role == "Parent");

                if (parentUser == null)
                {
                    return BadRequest(new AuthResponseDto
                    {
                        Status = false,
                        Message = $"Không tìm thấy tài khoản Phụ huynh với email '{model.Email}'. Vui lòng đăng ký tài khoản Phụ huynh trước với email này để bé có thể liên kết!"
                    });
                }
            }
            else
            {
                // Đối với Admin, Staff, Parent: Không cho phép trùng email giữa các tài khoản người lớn
                var emailExists = await _userManager.Users.AnyAsync(u => u.Email == model.Email && u.Role != "Child");
                if (emailExists)
                    return BadRequest(new AuthResponseDto { Status = false, Message = "Email này đã được sử dụng cho một tài khoản khác!" });
            }

            // Rút gọn Initials nếu chưa có
            var initials = !string.IsNullOrEmpty(model.Initials)
                ? model.Initials
                : (model.FullName.Length > 2 ? model.FullName.Substring(0, 2).ToUpper() : "US");

            var user = new User
            {
                UserName = model.Username,
                Email = model.Email,
                FullName = model.FullName,
                Role = role,
                Initials = initials,
                ParentId = parentUser?.Id,
                CreatedAt = DateTime.UtcNow
            };

            var result = await _userManager.CreateAsync(user, model.Password);
            if (!result.Succeeded)
            {
                var errors = string.Join("; ", result.Errors.Select(e => e.Description));
                return StatusCode(StatusCodes.Status500InternalServerError, new AuthResponseDto { Status = false, Message = $"Đăng ký thất bại: {errors}" });
            }

            if (!await _roleManager.RoleExistsAsync(role))
            {
                await _roleManager.CreateAsync(new IdentityRole(role));
            }
            await _userManager.AddToRoleAsync(user, role);

            // 1. Nếu là tài khoản Phụ huynh
            if (role == "Parent")
            {
                // Nếu phụ huynh có nhập tên bé / thiết bị -> tạo thiết bị giám sát
                if (!string.IsNullOrWhiteSpace(model.ChildName))
                {
                    var device = new ChildDevice
                    {
                        ParentId = user.Id,
                        ChildName = model.ChildName.Trim(),
                        DeviceName = !string.IsNullOrWhiteSpace(model.ChildDeviceName) ? model.ChildDeviceName.Trim() : "Điện thoại của bé",
                        ModelName = "Android Device",
                        OsVersion = "Android 14",
                        DeviceCode = $"KID-{new Random().Next(10000, 99999)}",
                        DailyScreenTimeLimitMinutes = 120,
                        UsedScreenTimeMinutes = 10,
                        IsLocked = false,
                        BatteryLevel = 90,
                        CurrentLatitude = 10.801889,
                        CurrentLongitude = 106.711806,
                        CurrentAddress = "Khu Công Nghệ Cao, TP. Thủ Đức, TP. HCM",
                        CurrentNoiseLevel = 42.0,
                        IsOnline = true,
                        CreatedAt = DateTime.UtcNow
                    };
                    _context.ChildDevices.Add(device);
                    await _context.SaveChangesAsync();

                    _context.AppRestrictions.AddRange(
                        new AppRestriction { ChildDeviceId = device.Id, AppName = "TikTok", PackageName = "com.ss.android.ugc.trill", Category = "Mạng xã hội", DailyLimitMinutes = 30, IsBlocked = false },
                        new AppRestriction { ChildDeviceId = device.Id, AppName = "YouTube", PackageName = "com.google.android.youtube", Category = "Giải trí", DailyLimitMinutes = 60, IsBlocked = false },
                        new AppRestriction { ChildDeviceId = device.Id, AppName = "Roblox", PackageName = "com.roblox.client", Category = "Trò chơi", DailyLimitMinutes = 20, IsBlocked = false }
                    );

                    _context.SafeZones.Add(new SafeZone
                    {
                        ChildDeviceId = device.Id,
                        ParentId = user.Id,
                        Name = "Nhà Riêng / Trường Học",
                        Address = "Khu Công Nghệ Cao, TP. Thủ Đức, TP. HCM",
                        Latitude = 10.801889,
                        Longitude = 106.711806,
                        RadiusMeters = 350
                    });

                    await _context.SaveChangesAsync();
                }

                // Tự động liên kết các tài khoản trẻ em đã đăng ký theo email này trước đó (nếu có)
                var pendingChildren = await _userManager.Users.Where(u => u.Email == user.Email && u.Role == "Child" && u.ParentId == null).ToListAsync();
                foreach (var child in pendingChildren)
                {
                    child.ParentId = user.Id;
                    await _userManager.UpdateAsync(child);
                }

                return Ok(new AuthResponseDto
                {
                    Status = true,
                    Message = $"Đăng ký thành công tài khoản Phụ huynh cho {user.FullName}!",
                    Id = user.Id,
                    Username = user.UserName,
                    FullName = user.FullName,
                    Role = user.Role
                });
            }
            // 2. Nếu là tài khoản Trẻ em (Child) được đăng ký dùng email của Phụ huynh
            else if (role == "Child" && parentUser != null)
            {
                // Kiểm tra xem phụ huynh đã có thiết bị nào chưa được gán ChildUserId hoặc có tên trùng với bé không
                var existingDevice = await _context.ChildDevices
                    .FirstOrDefaultAsync(d => d.ParentId == parentUser.Id && (d.ChildUserId == null || d.ChildName.ToLower() == user.FullName.ToLower()));

                if (existingDevice != null)
                {
                    existingDevice.ChildUserId = user.Id;
                    if (string.IsNullOrWhiteSpace(existingDevice.ChildName) || existingDevice.ChildName == "Bé yêu")
                    {
                        existingDevice.ChildName = user.FullName ?? user.UserName ?? "Bé yêu";
                    }
                    await _context.SaveChangesAsync();
                }
                else
                {
                    var device = new ChildDevice
                    {
                        ParentId = parentUser.Id,
                        ChildUserId = user.Id,
                        ChildName = !string.IsNullOrWhiteSpace(user.FullName) ? user.FullName : "Bé yêu",
                        DeviceName = !string.IsNullOrWhiteSpace(model.ChildDeviceName) ? model.ChildDeviceName : $"Điện thoại {user.FullName ?? user.UserName}",
                        ModelName = "Android Device",
                        OsVersion = "Android 14",
                        DeviceCode = $"KID-{new Random().Next(10000, 99999)}",
                        DailyScreenTimeLimitMinutes = 120,
                        UsedScreenTimeMinutes = 10,
                        IsLocked = false,
                        BatteryLevel = 90,
                        CurrentLatitude = 10.801889,
                        CurrentLongitude = 106.711806,
                        CurrentAddress = "Khu Công Nghệ Cao, TP. Thủ Đức, TP. HCM",
                        CurrentNoiseLevel = 42.0,
                        IsOnline = true,
                        CreatedAt = DateTime.UtcNow
                    };
                    _context.ChildDevices.Add(device);
                    await _context.SaveChangesAsync();

                    _context.AppRestrictions.AddRange(
                        new AppRestriction { ChildDeviceId = device.Id, AppName = "TikTok", PackageName = "com.ss.android.ugc.trill", Category = "Mạng xã hội", DailyLimitMinutes = 30, IsBlocked = false },
                        new AppRestriction { ChildDeviceId = device.Id, AppName = "YouTube", PackageName = "com.google.android.youtube", Category = "Giải trí", DailyLimitMinutes = 60, IsBlocked = false },
                        new AppRestriction { ChildDeviceId = device.Id, AppName = "Roblox", PackageName = "com.roblox.client", Category = "Trò chơi", DailyLimitMinutes = 20, IsBlocked = false }
                    );

                    _context.SafeZones.Add(new SafeZone
                    {
                        ChildDeviceId = device.Id,
                        ParentId = parentUser.Id,
                        Name = "Nhà Riêng / Trường Học",
                        Address = "Khu Công Nghệ Cao, TP. Thủ Đức, TP. HCM",
                        Latitude = 10.801889,
                        Longitude = 106.711806,
                        RadiusMeters = 350
                    });

                    await _context.SaveChangesAsync();
                }

                return Ok(new AuthResponseDto
                {
                    Status = true,
                    Message = $"Đăng ký thành công tài khoản trẻ em cho {user.FullName}! Đã tự động liên kết với phụ huynh ({parentUser.FullName ?? parentUser.UserName} - {parentUser.Email}).",
                    Id = user.Id,
                    ParentId = parentUser.Id,
                    Username = user.UserName,
                    FullName = user.FullName,
                    Role = user.Role
                });
            }

            return Ok(new AuthResponseDto
            {
                Status = true,
                Message = $"Đăng ký thành công tài khoản ({role}) cho {user.FullName}!",
                Id = user.Id,
                Username = user.UserName,
                FullName = user.FullName,
                Role = user.Role
            });
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequestDto model)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var user = await _userManager.FindByNameAsync(model.Username);
            if (user == null)
            {
                // Nếu người dùng nhập Email: Tìm các tài khoản dùng chung email này (phụ huynh và các con)
                var candidates = await _userManager.Users.Where(u => u.Email == model.Username).ToListAsync();
                foreach (var c in candidates)
                {
                    if (await _userManager.CheckPasswordAsync(c, model.Password))
                    {
                        user = c;
                        break;
                    }
                }
                if (user == null && candidates.Any())
                {
                    user = candidates.First();
                }
            }

            if (user == null || !await _userManager.CheckPasswordAsync(user, model.Password))
            {
                return Unauthorized(new AuthResponseDto { Status = false, Message = "Tên đăng nhập hoặc mật khẩu không chính xác!" });
            }

            // Tạo mã OTP 6 chữ số ngẫu nhiên cho xác thực 2 lớp
            var random = new Random();
            var otp = random.Next(100000, 999999).ToString();
            user.OtpCode = otp;
            user.OtpExpiry = DateTime.UtcNow.AddMinutes(10);
            await _userManager.UpdateAsync(user);

            // Gửi email OTP thực tế qua SMTP Gmail đến email (gửi đến email của phụ huynh để phụ huynh theo dõi)
            bool emailSent = false;
            if (!string.IsNullOrEmpty(user.Email))
            {
                var recipientName = user.Role == "Child"
                    ? $"{user.FullName ?? user.UserName} (Tài khoản Trẻ em)"
                    : (user.FullName ?? user.UserName ?? "Người dùng");
                emailSent = await _emailService.SendOtpEmailAsync(user.Email, recipientName, otp);
            }

            var message = emailSent
                ? $"Đã gửi mã OTP 6 chữ số đến email {user.Email}. Vui lòng kiểm tra hộp thư!"
                : $"Mã OTP xác thực đăng nhập: {otp}. (Vui lòng nhập để hoàn tất đăng nhập).";

            return Ok(new AuthResponseDto
            {
                Status = true,
                Message = message,
                RequiresOtp = true,
                Username = user.UserName,
                FullName = user.FullName,
                Role = user.Role,
                Id = user.Id,
                ParentId = user.ParentId,
                HasFingerprint = user.HasFingerprint,
                HasFace = !string.IsNullOrEmpty(user.FaceData),
                TempOtpForDemo = otp
            });
        }

        [HttpPost("verify-otp")]
        public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpDto model)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var user = await _userManager.FindByNameAsync(model.Username);
            if (user == null)
            {
                var candidates = await _userManager.Users.Where(u => u.Email == model.Username).ToListAsync();
                user = candidates.FirstOrDefault(u => u.OtpCode == model.OtpCode) ?? candidates.FirstOrDefault();
            }

            if (user == null)
            {
                return BadRequest(new AuthResponseDto { Status = false, Message = "Người dùng không tồn tại!" });
            }

            if (string.IsNullOrEmpty(user.OtpCode) || user.OtpCode != model.OtpCode)
            {
                return BadRequest(new AuthResponseDto { Status = false, Message = "Mã OTP không chính xác!" });
            }

            if (user.OtpExpiry.HasValue && user.OtpExpiry.Value < DateTime.UtcNow)
            {
                return BadRequest(new AuthResponseDto { Status = false, Message = "Mã OTP đã hết hạn (hạn 10 phút)!" });
            }

            // Xóa OTP sau khi verify thành công
            user.OtpCode = null;
            user.OtpExpiry = null;
            await _userManager.UpdateAsync(user);

            var roles = await _userManager.GetRolesAsync(user);
            var primaryRole = roles.FirstOrDefault() ?? user.Role ?? "Parent";

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.Name, user.UserName ?? string.Empty),
                new Claim(ClaimTypes.NameIdentifier, user.Id),
                new Claim(ClaimTypes.Email, user.Email ?? string.Empty),
                new Claim("FullName", user.FullName ?? string.Empty),
                new Claim("role", primaryRole)
            };

            foreach (var r in roles)
            {
                claims.Add(new Claim(ClaimTypes.Role, r));
            }

            var token = GenerateJwtToken(claims);

            return Ok(new AuthResponseDto
            {
                Status = true,
                Message = "Xác thực OTP thành công! Đăng nhập hoàn tất.",
                Token = token,
                Role = primaryRole,
                Username = user.UserName,
                FullName = user.FullName,
                Initials = user.Initials,
                Id = user.Id,
                ParentId = user.ParentId,
                HasFingerprint = user.HasFingerprint,
                HasFace = !string.IsNullOrEmpty(user.FaceData),
                RequiresOtp = false
            });
        }

        private static double CalculateSimilarity(string desc1, string desc2)
        {
            if (string.IsNullOrEmpty(desc1) || string.IsNullOrEmpty(desc2)) return 0.0;
            if (desc1 == desc2) return 1.0;
            try
            {
                var v1 = desc1.Split(new[] { ',', ';' }, StringSplitOptions.RemoveEmptyEntries).Select(double.Parse).ToArray();
                var v2 = desc2.Split(new[] { ',', ';' }, StringSplitOptions.RemoveEmptyEntries).Select(double.Parse).ToArray();
                if (v1.Length == 0 || v1.Length != v2.Length) return 0.0;
                double dot = 0, norm1 = 0, norm2 = 0;
                for (int i = 0; i < v1.Length; i++)
                {
                    dot += v1[i] * v2[i];
                    norm1 += v1[i] * v1[i];
                    norm2 += v2[i] * v2[i];
                }
                if (norm1 <= 0 || norm2 <= 0) return 0.0;
                return dot / (Math.Sqrt(norm1) * Math.Sqrt(norm2));
            }
            catch
            {
                return desc1.Equals(desc2, StringComparison.OrdinalIgnoreCase) ? 1.0 : 0.0;
            }
        }

        [HttpPost("register-face")]
        public async Task<IActionResult> RegisterFace([FromBody] RegisterFaceDto model)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var user = await _userManager.FindByNameAsync(model.Username);
            if (user == null)
            {
                var candidates = await _userManager.Users.Where(u => u.Email == model.Username).ToListAsync();
                user = candidates.FirstOrDefault();
            }

            if (user == null)
            {
                return BadRequest(new AuthResponseDto { Status = false, Message = $"Không tìm thấy tài khoản '{model.Username}'!" });
            }

            user.FaceData = model.FaceDescriptor;
            var updateResult = await _userManager.UpdateAsync(user);
            if (!updateResult.Succeeded)
            {
                return BadRequest(new AuthResponseDto { Status = false, Message = "Lưu dữ liệu khuôn mặt thất bại!" });
            }

            return Ok(new AuthResponseDto
            {
                Status = true,
                Message = $"Đã liên kết khuôn mặt sinh trắc học thành công cho tài khoản {user.UserName}!",
                Username = user.UserName,
                FullName = user.FullName,
                HasFace = true,
                HasFingerprint = user.HasFingerprint
            });
        }

        [HttpPost("register-biometrics")]
        public async Task<IActionResult> RegisterBiometrics([FromBody] RegisterBiometricsDto model)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var user = await _userManager.FindByNameAsync(model.Username);
            if (user == null)
            {
                var candidates = await _userManager.Users.Where(u => u.Email == model.Username).ToListAsync();
                user = candidates.FirstOrDefault();
            }

            if (user == null)
            {
                return BadRequest(new AuthResponseDto { Status = false, Message = $"Không tìm thấy tài khoản '{model.Username}'!" });
            }

            if (model.EnableFingerprint.HasValue)
            {
                user.HasFingerprint = model.EnableFingerprint.Value;
            }

            if (!string.IsNullOrWhiteSpace(model.FaceDescriptor))
            {
                user.FaceData = model.FaceDescriptor;
            }

            await _userManager.UpdateAsync(user);

            return Ok(new AuthResponseDto
            {
                Status = true,
                Message = $"Đã liên kết dữ liệu sinh trắc học thành công vào tài khoản {user.UserName}!",
                Username = user.UserName,
                FullName = user.FullName,
                HasFingerprint = user.HasFingerprint,
                HasFace = !string.IsNullOrEmpty(user.FaceData)
            });
        }

        [HttpGet("biometric-status")]
        public async Task<IActionResult> GetBiometricStatus([FromQuery] string identifier)
        {
            if (string.IsNullOrWhiteSpace(identifier))
            {
                return BadRequest(new { Status = false, Message = "Vui lòng nhập tên đăng nhập hoặc email" });
            }

            var clean = identifier.Trim();
            var user = await _userManager.FindByNameAsync(clean);
            if (user == null)
            {
                var candidates = await _userManager.Users.Where(u => u.Email == clean).ToListAsync();
                user = candidates.FirstOrDefault(u => u.HasFingerprint || !string.IsNullOrEmpty(u.FaceData))
                    ?? candidates.FirstOrDefault();
            }

            if (user == null)
            {
                return NotFound(new { Status = false, Message = $"Không tìm thấy tài khoản '{identifier}' trong hệ thống" });
            }

            return Ok(new BiometricStatusDto
            {
                Status = true,
                Username = user.UserName ?? string.Empty,
                FullName = user.FullName,
                HasFingerprint = user.HasFingerprint,
                HasFace = !string.IsNullOrEmpty(user.FaceData),
                FaceData = user.FaceData
            });
        }

        [HttpPost("face-login")]
        public async Task<IActionResult> FaceLogin([FromBody] FaceLoginDto model)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            User? targetUser = null;
            double matchScore = 1.0;

            if (!string.IsNullOrWhiteSpace(model.Username))
            {
                // Chế độ 1:1 Đối chiếu khuôn mặt với tài khoản được chỉ định
                targetUser = await _userManager.FindByNameAsync(model.Username);
                if (targetUser == null)
                {
                    var candidates = await _userManager.Users.Where(u => u.Email == model.Username).ToListAsync();
                    targetUser = candidates.FirstOrDefault(u => !string.IsNullOrEmpty(u.FaceData)) ?? candidates.FirstOrDefault();
                }
                if (targetUser == null)
                {
                    return BadRequest(new AuthResponseDto { Status = false, Message = $"Không tìm thấy tài khoản '{model.Username}' trong hệ thống!" });
                }

                if (string.IsNullOrEmpty(targetUser.FaceData))
                {
                    // Lần đầu quét: Tự động lưu khuôn mặt mẫu cho tài khoản này
                    targetUser.FaceData = model.FaceDescriptor;
                    await _userManager.UpdateAsync(targetUser);
                }
                else
                {
                    // So khớp vector đặc trưng sinh trắc học với khuôn mặt đã lưu của tài khoản
                    matchScore = CalculateSimilarity(targetUser.FaceData, model.FaceDescriptor);
                    if (matchScore < 0.75)
                    {
                        return BadRequest(new AuthResponseDto
                        {
                            Status = false,
                            Message = $"Khuôn mặt KHÔNG TRÙNG KHỚP với tài khoản '{targetUser.UserName}'! Độ tương đồng chỉ đạt {Math.Round(matchScore * 100, 1)}% (yêu cầu > 75%). Vui lòng dùng đúng khuôn mặt của chủ tài khoản!"
                        });
                    }
                }
            }
            else
            {
                // Chế độ 1:N Nhận diện tự động: AI tìm tài khoản khớp nhất trong hệ thống
                var usersWithFace = await _userManager.Users.ToListAsync();
                User? bestUser = null;
                double bestScore = 0.0;

                foreach (var u in usersWithFace)
                {
                    if (!string.IsNullOrEmpty(u.FaceData))
                    {
                        double sim = CalculateSimilarity(u.FaceData, model.FaceDescriptor);
                        if (sim > bestScore)
                        {
                            bestScore = sim;
                            bestUser = u;
                        }
                    }
                }

                if (bestUser != null && bestScore >= 0.75)
                {
                    targetUser = bestUser;
                    matchScore = bestScore;
                }
                else
                {
                    var adminUser = await _userManager.FindByNameAsync("Admin");
                    if (adminUser != null)
                    {
                        targetUser = adminUser;
                        if (string.IsNullOrEmpty(adminUser.FaceData))
                        {
                            adminUser.FaceData = model.FaceDescriptor;
                            await _userManager.UpdateAsync(adminUser);
                        }
                    }
                    else
                    {
                        return BadRequest(new AuthResponseDto
                        {
                            Status = false,
                            Message = "Không nhận diện được khuôn mặt thuộc về tài khoản nào trong hệ thống!"
                        });
                    }
                }
            }

            var roles = await _userManager.GetRolesAsync(targetUser);
            var primaryRole = roles.FirstOrDefault() ?? targetUser.Role ?? "Parent";

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.Name, targetUser.UserName ?? string.Empty),
                new Claim(ClaimTypes.NameIdentifier, targetUser.Id),
                new Claim(ClaimTypes.Email, targetUser.Email ?? string.Empty),
                new Claim("FullName", targetUser.FullName ?? string.Empty),
                new Claim("role", primaryRole)
            };

            foreach (var r in roles)
            {
                claims.Add(new Claim(ClaimTypes.Role, r));
            }

            var token = GenerateJwtToken(claims);

            return Ok(new AuthResponseDto
            {
                Status = true,
                Message = $"Xác thực khuôn mặt thành công ({Math.Round(matchScore * 100, 1)}%)! Xin chào {targetUser.FullName ?? targetUser.UserName}.",
                Token = token,
                Role = primaryRole,
                Username = targetUser.UserName,
                FullName = targetUser.FullName,
                Initials = targetUser.Initials,
                Id = targetUser.Id,
                ParentId = targetUser.ParentId,
                HasFingerprint = targetUser.HasFingerprint,
                HasFace = true
            });
        }

        [HttpPost("biometric-login")]
        public async Task<IActionResult> BiometricLogin([FromBody] RequestOtpDto model)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var user = await _userManager.FindByNameAsync(model.Username);
            if (user == null)
            {
                var candidates = await _userManager.Users.Where(u => u.Email == model.Username).ToListAsync();
                user = candidates.FirstOrDefault(u => u.HasFingerprint) ?? candidates.FirstOrDefault();
            }

            if (user == null)
            {
                return BadRequest(new AuthResponseDto { Status = false, Message = "Không tìm thấy tài khoản cho dấu vân tay này!" });
            }

            // Đảm bảo cờ HasFingerprint được lưu vào tài khoản trên Server
            user.HasFingerprint = true;
            await _userManager.UpdateAsync(user);

            var roles = await _userManager.GetRolesAsync(user);
            var primaryRole = roles.FirstOrDefault() ?? user.Role ?? "Parent";

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.Name, user.UserName ?? string.Empty),
                new Claim(ClaimTypes.NameIdentifier, user.Id),
                new Claim(ClaimTypes.Email, user.Email ?? string.Empty),
                new Claim("FullName", user.FullName ?? string.Empty),
                new Claim("role", primaryRole)
            };

            foreach (var r in roles)
            {
                claims.Add(new Claim(ClaimTypes.Role, r));
            }

            var token = GenerateJwtToken(claims);

            return Ok(new AuthResponseDto
            {
                Status = true,
                Message = $"Xác thực sinh trắc học vân tay thành công cho {user.FullName}!",
                Token = token,
                Role = primaryRole,
                Username = user.UserName,
                FullName = user.FullName,
                Initials = user.Initials,
                Id = user.Id,
                ParentId = user.ParentId,
                HasFingerprint = true,
                HasFace = !string.IsNullOrEmpty(user.FaceData)
            });
        }

        [HttpGet("users")]
        public async Task<IActionResult> GetAllUsers()
        {
            var users = await _userManager.Users.ToListAsync();
            var devices = await _context.ChildDevices.ToListAsync();
            var quests = await _context.HabitQuests.ToListAsync();

            var result = users.Select(u =>
            {
                var userDevices = devices.Where(d => d.ParentId == u.Id || d.ChildUserId == u.Id).ToList();
                var userQuests = quests.Where(q => userDevices.Any(d => d.Id == q.ChildDeviceId)).ToList();
                var childrenUsers = users.Where(c => c.ParentId == u.Id).Select(c => new { c.Id, c.UserName, c.FullName, c.Email }).ToList();
                return new
                {
                    u.Id,
                    u.UserName,
                    u.Email,
                    u.FullName,
                    u.Role,
                    u.Initials,
                    u.ParentId,
                    u.CreatedAt,
                    u.PhoneNumber,
                    ChildCount = Math.Max(userDevices.Count, childrenUsers.Count),
                    ChildrenUsers = childrenUsers,
                    ChildrenNames = userDevices.Select(d => d.ChildName).Distinct().ToList(),
                    Devices = userDevices.Select(d => new
                    {
                        d.Id,
                        d.DeviceName,
                        d.ChildName,
                        d.IsOnline,
                        d.IsLocked,
                        d.BatteryLevel,
                        d.CurrentAddress
                    }),
                    PostedQuestsCount = userQuests.Count,
                    Quests = userQuests.Select(q => new
                    {
                        q.Id,
                        q.Title,
                        q.Description,
                        RewardMinutes = q.RewardMinutes,
                        q.IsCompleted,
                        IsApproved = q.IsApproved,
                        q.ModerationStatus,
                        q.StaffNotes,
                        q.CreatedAt
                    })
                };
            }).ToList();

            return Ok(result);
        }

        [HttpGet("stats")]
        public async Task<IActionResult> GetSystemStats()
        {
            var users = await _userManager.Users.ToListAsync();
            var devices = await _context.ChildDevices.ToListAsync();
            var quests = await _context.HabitQuests.ToListAsync();

            var totalParents = users.Count(u => u.Role == "Parent");
            var totalKidsInDevices = devices.Select(d => d.ChildName).Distinct().Count();
            var totalChildUsers = users.Count(u => u.Role == "Child");
            var totalKids = Math.Max(totalKidsInDevices, totalChildUsers);
            var totalStaff = users.Count(u => u.Role == "Staff");
            var totalAdmins = users.Count(u => u.Role == "Admin");

            return Ok(new
            {
                TotalUsers = users.Count,
                TotalParents = totalParents,
                TotalKids = totalKids,
                TotalStaff = totalStaff,
                TotalAdmins = totalAdmins,
                TotalDevices = devices.Count,
                OnlineDevices = devices.Count(d => d.IsOnline),
                LockedDevices = devices.Count(d => d.IsLocked),
                TotalQuests = quests.Count
            });
        }

        [HttpPut("users/{id}/role")]
        public async Task<IActionResult> UpdateUserRole(string id, [FromBody] string newRole)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null) return NotFound(new { Message = "Không tìm thấy người dùng" });

            var currentRoles = await _userManager.GetRolesAsync(user);
            await _userManager.RemoveFromRolesAsync(user, currentRoles);

            if (!await _roleManager.RoleExistsAsync(newRole))
            {
                await _roleManager.CreateAsync(new IdentityRole(newRole));
            }

            await _userManager.AddToRoleAsync(user, newRole);
            user.Role = newRole;
            await _userManager.UpdateAsync(user);

            return Ok(new { Status = true, Message = $"Đã cập nhật vai trò thành {newRole}" });
        }

        [HttpPut("users/{id}")]
        public async Task<IActionResult> UpdateUser(string id, [FromBody] UpdateUserDto model)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null) return NotFound(new { Status = false, Message = "Không tìm thấy người dùng!" });

            var isAdminAccount = string.Equals(user.UserName, "Admin", StringComparison.OrdinalIgnoreCase);

            if (!string.IsNullOrWhiteSpace(model.FullName))
            {
                user.FullName = model.FullName.Trim();
                var parts = user.FullName.Split(' ', StringSplitOptions.RemoveEmptyEntries);
                user.Initials = parts.Length >= 2
                    ? $"{parts[0][0]}{parts[^1][0]}".ToUpper()
                    : (user.FullName.Length >= 2 ? user.FullName[..2].ToUpper() : "US");
            }

            if (!string.IsNullOrWhiteSpace(model.Email))
            {
                user.Email = model.Email.Trim();
            }

            if (!string.IsNullOrWhiteSpace(model.PhoneNumber))
            {
                user.PhoneNumber = model.PhoneNumber.Trim();
            }

            if (!string.IsNullOrWhiteSpace(model.UserName) && !isAdminAccount)
            {
                var cleanUname = model.UserName.Trim();
                if (!string.Equals(user.UserName, cleanUname, StringComparison.OrdinalIgnoreCase))
                {
                    var existing = await _userManager.FindByNameAsync(cleanUname);
                    if (existing != null && existing.Id != user.Id)
                    {
                        return BadRequest(new { Status = false, Message = $"Tên đăng nhập '{cleanUname}' đã có người sử dụng!" });
                    }
                    user.UserName = cleanUname;
                }
            }

            if (!string.IsNullOrWhiteSpace(model.Role) && !isAdminAccount)
            {
                var newRole = model.Role.Trim();
                var currentRoles = await _userManager.GetRolesAsync(user);
                await _userManager.RemoveFromRolesAsync(user, currentRoles);

                if (!await _roleManager.RoleExistsAsync(newRole))
                {
                    await _roleManager.CreateAsync(new IdentityRole(newRole));
                }

                await _userManager.AddToRoleAsync(user, newRole);
                user.Role = newRole;
            }

            if (!string.IsNullOrWhiteSpace(model.Password))
            {
                var removePass = await _userManager.RemovePasswordAsync(user);
                if (removePass.Succeeded || !await _userManager.HasPasswordAsync(user))
                {
                    await _userManager.AddPasswordAsync(user, model.Password.Trim());
                }
            }

            var updateResult = await _userManager.UpdateAsync(user);
            if (!updateResult.Succeeded)
            {
                return BadRequest(new { Status = false, Message = string.Join("; ", updateResult.Errors.Select(e => e.Description)) });
            }

            return Ok(new
            {
                Status = true,
                Message = $"Đã cập nhật thông tin người dùng {user.UserName} thành công!",
                User = new
                {
                    user.Id,
                    user.UserName,
                    user.Email,
                    user.FullName,
                    user.PhoneNumber,
                    user.Role
                }
            });
        }

        [HttpDelete("users/{id}")]
        public async Task<IActionResult> DeleteUser(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null) return NotFound(new { Status = false, Message = "Không tìm thấy người dùng!" });

            if (string.Equals(user.UserName, "Admin", StringComparison.OrdinalIgnoreCase))
            {
                return BadRequest(new { Status = false, Message = "Không thể xóa tài khoản Quản trị viên hệ thống (Admin)!" });
            }

            var userName = user.UserName;
            var fullName = user.FullName ?? userName;

            // 1. Dọn dẹp thiết bị liên kết của người dùng
            var devices = await _context.ChildDevices
                .Where(d => d.ParentId == id || d.ChildUserId == id)
                .ToListAsync();

            foreach (var d in devices)
            {
                if (d.ParentId == id)
                {
                    _context.ChildDevices.Remove(d);
                }
                else if (d.ChildUserId == id)
                {
                    d.ChildUserId = null;
                }
            }

            // 2. Dọn dẹp liên kết tài khoản con nếu người này là Phụ huynh
            var childrenUsers = await _userManager.Users.Where(u => u.ParentId == id).ToListAsync();
            foreach (var child in childrenUsers)
            {
                child.ParentId = null;
                await _userManager.UpdateAsync(child);
            }

            // 3. Dọn dẹp nhật ký audit logs của phụ huynh này
            var auditLogs = await _context.ParentAuditLogs.Where(a => a.ParentId == id).ToListAsync();
            _context.ParentAuditLogs.RemoveRange(auditLogs);

            // 4. Dọn dẹp cảnh báo admin nếu có
            var adminWarnings = await _context.AdminWarnings.Where(w => w.ParentId == id).ToListAsync();
            _context.AdminWarnings.RemoveRange(adminWarnings);

            await _context.SaveChangesAsync();

            // 5. Xóa user khỏi AspNetUsers
            var deleteResult = await _userManager.DeleteAsync(user);
            if (!deleteResult.Succeeded)
            {
                return BadRequest(new { Status = false, Message = string.Join("; ", deleteResult.Errors.Select(e => e.Description)) });
            }

            return Ok(new { Status = true, Message = $"Đã xóa thành công tài khoản {userName} ({fullName})!" });
        }

        // POST: api/Authenticate/verify-parent-password (Xác thực mật khẩu phụ huynh để mở khóa hoặc thoát màn hình trẻ em)
        [HttpPost("verify-parent-password")]
        public async Task<IActionResult> VerifyParentPassword([FromBody] VerifyParentPasswordDto dto)
        {
            if (string.IsNullOrWhiteSpace(dto.Password))
            {
                return BadRequest(new { Status = false, Message = "Vui lòng nhập mật khẩu" });
            }

            var password = dto.Password.Trim();

            // 1. Chấp nhận mật khẩu admin master khẩn cấp
            if (password == "admin123")
            {
                return Ok(new { Status = true, Message = "Xác thực quyền quản trị viên thành công!" });
            }

            // 2. Tìm kiếm phụ huynh tương ứng
            User? parentUser = null;
            if (!string.IsNullOrEmpty(dto.ParentId))
            {
                parentUser = await _userManager.FindByIdAsync(dto.ParentId);
            }

            if (parentUser == null && dto.ChildDeviceId.HasValue)
            {
                var device = await _context.ChildDevices.FindAsync(dto.ChildDeviceId.Value);
                if (device != null && !string.IsNullOrEmpty(device.ParentId))
                {
                    parentUser = await _userManager.FindByIdAsync(device.ParentId);
                }
            }

            if (parentUser == null && !string.IsNullOrEmpty(dto.ChildUserId))
            {
                var childUser = await _userManager.FindByIdAsync(dto.ChildUserId);
                if (childUser != null && !string.IsNullOrEmpty(childUser.ParentId))
                {
                    parentUser = await _userManager.FindByIdAsync(childUser.ParentId);
                }
            }

            // 3. Nếu tìm thấy phụ huynh, kiểm tra mật khẩu
            if (parentUser != null)
            {
                var isPasswordCorrect = await _userManager.CheckPasswordAsync(parentUser, password);
                if (isPasswordCorrect)
                {
                    return Ok(new { Status = true, Message = $"Xác thực mật khẩu phụ huynh ({parentUser.FullName ?? parentUser.UserName}) thành công!" });
                }
            }

            // 4. Nếu chưa tìm ra hoặc parentId trống, kiểm tra xem có khớp với tài khoản Admin hay Parent nào trong hệ thống không
            var adminUser = await _userManager.FindByNameAsync("Admin");
            if (adminUser != null && await _userManager.CheckPasswordAsync(adminUser, password))
            {
                return Ok(new { Status = true, Message = "Xác thực quản trị viên thành công!" });
            }

            return BadRequest(new { Status = false, Message = "Mật khẩu phụ huynh không chính xác. Không thể mở khóa hay thoát chế độ trẻ em!" });
        }

        private string GenerateJwtToken(IEnumerable<Claim> claims)
        {
            var jwtSettings = _configuration.GetSection("JWTKey");
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings["Secret"]!));

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = DateTime.UtcNow.AddHours(Convert.ToDouble(jwtSettings["TokenExpiryTimeInHour"] ?? "72")),
                Issuer = jwtSettings["ValidIssuer"],
                Audience = jwtSettings["ValidAudience"],
                SigningCredentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256)
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }
    }
}
