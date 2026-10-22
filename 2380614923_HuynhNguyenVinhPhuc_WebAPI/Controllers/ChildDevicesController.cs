using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using _2380614923_HuynhNguyenVinhPhuc_WebAPI.Data;
using _2380614923_HuynhNguyenVinhPhuc_WebAPI.Models;

namespace _2380614923_HuynhNguyenVinhPhuc_WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ChildDevicesController : ControllerBase
    {
        private readonly KidGuardDbContext _context;

        public ChildDevicesController(KidGuardDbContext context)
        {
            _context = context;
        }

        // GET: api/ChildDevices
        [HttpGet]
        public async Task<IActionResult> GetDevices([FromQuery] string? parentId, [FromQuery] string? childUserId)
        {
            var query = _context.ChildDevices
                .Include(d => d.AppRestrictions)
                .Include(d => d.SafeZones)
                .Include(d => d.SecurityAlerts.OrderByDescending(a => a.CreatedAt).Take(5))
                .AsQueryable();

            if (!string.IsNullOrEmpty(parentId))
            {
                query = query.Where(d => d.ParentId == parentId);
            }

            if (!string.IsNullOrEmpty(childUserId))
            {
                query = query.Where(d => d.ChildUserId == childUserId);
            }

            var devices = await query.ToListAsync();
            return Ok(devices);
        }

        // GET: api/ChildDevices/5
        [HttpGet("{id}")]
        public async Task<IActionResult> GetDevice(int id)
        {
            var device = await _context.ChildDevices
                .Include(d => d.AppRestrictions)
                .Include(d => d.SafeZones)
                .Include(d => d.SecurityAlerts.OrderByDescending(a => a.CreatedAt))
                .Include(d => d.HabitQuests)
                .FirstOrDefaultAsync(d => d.Id == id);

            if (device == null)
            {
                return NotFound(new { Message = "Không tìm thấy thiết bị của trẻ" });
            }

            return Ok(device);
        }

        // POST: api/ChildDevices (Tạo mới thiết bị và mã QR ghép đôi)
        [HttpPost]
        public async Task<IActionResult> CreateDevice([FromBody] ChildDevice device)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            if (string.IsNullOrEmpty(device.DeviceCode))
            {
                device.DeviceCode = $"KID-{new Random().Next(10000, 99999)}";
            }

            device.CreatedAt = DateTime.UtcNow;
            _context.ChildDevices.Add(device);
            await _context.SaveChangesAsync();

            // Tự động tạo một số app mặc định để quản lý ngay
            var sampleApps = new List<AppRestriction>
            {
                new AppRestriction { ChildDeviceId = device.Id, AppName = "TikTok", PackageName = "com.ss.android.ugc.trill", Category = "Mạng xã hội", DailyLimitMinutes = 30, IsBlocked = false },
                new AppRestriction { ChildDeviceId = device.Id, AppName = "YouTube", PackageName = "com.google.android.youtube", Category = "Giải trí", DailyLimitMinutes = 60, IsBlocked = false },
                new AppRestriction { ChildDeviceId = device.Id, AppName = "Roblox", PackageName = "com.roblox.client", Category = "Game", DailyLimitMinutes = 20, IsBlocked = false },
                new AppRestriction { ChildDeviceId = device.Id, AppName = "Facebook", PackageName = "com.facebook.katana", Category = "Mạng xã hội", DailyLimitMinutes = 0, IsBlocked = true }
            };
            _context.AppRestrictions.AddRange(sampleApps);

            // Tự động tạo 1 vùng an toàn mặc định (Nhà riêng)
            var defaultSafeZone = new SafeZone
            {
                ChildDeviceId = device.Id,
                ParentId = device.ParentId,
                Name = "Trường Học / Nhà Riêng",
                Address = "Khu Công Nghệ Cao, TP. Thủ Đức, TP. HCM",
                Latitude = device.CurrentLatitude,
                Longitude = device.CurrentLongitude,
                RadiusMeters = 400
            };
            if (!string.IsNullOrEmpty(device.ParentId))
            {
                _context.ParentAuditLogs.Add(new ParentAuditLog
                {
                    ParentId = device.ParentId,
                    ParentName = "Phụ huynh",
                    ActionType = "ADD_DEVICE",
                    TargetName = device.DeviceName,
                    Details = $"Thêm thiết bị con trẻ: {device.DeviceName} (Mã: {device.DeviceCode}) cho bé {device.ChildName}",
                    CreatedAt = DateTime.UtcNow
                });
            }

            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetDevice), new { id = device.Id }, device);
        }

        // PUT: api/ChildDevices/5 (Cập nhật thông tin thiết bị)
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateDevice(int id, [FromBody] ChildDevice updated)
        {
            var device = await _context.ChildDevices.FindAsync(id);
            if (device == null) return NotFound(new { Message = "Không tìm thấy thiết bị" });

            device.DeviceName = updated.DeviceName;
            device.ChildName = updated.ChildName;
            device.DailyScreenTimeLimitMinutes = updated.DailyScreenTimeLimitMinutes;
            device.UsedScreenTimeMinutes = updated.UsedScreenTimeMinutes;
            device.IsLocked = updated.IsLocked;
            device.BatteryLevel = updated.BatteryLevel;

            await _context.SaveChangesAsync();
            return Ok(new { Status = true, Message = "Cập nhật thiết bị thành công", Device = device });
        }

        // PUT: api/ChildDevices/5/lock (Khóa / Mở khóa thiết bị từ xa)
        [HttpPut("{id}/lock")]
        public async Task<IActionResult> ToggleLockDevice(int id, [FromBody] bool isLocked)
        {
            var device = await _context.ChildDevices.FindAsync(id);
            if (device == null) return NotFound(new { Message = "Không tìm thấy thiết bị" });

            device.IsLocked = isLocked;
            await _context.SaveChangesAsync();

            // Ghi nhận nhật ký audit của phụ huynh
            if (!string.IsNullOrEmpty(device.ParentId))
            {
                _context.ParentAuditLogs.Add(new ParentAuditLog
                {
                    ParentId = device.ParentId,
                    ParentName = "Phụ huynh",
                    ActionType = isLocked ? "LOCK_DEVICE" : "UNLOCK_DEVICE",
                    TargetName = device.DeviceName,
                    Details = $"{(isLocked ? "Khóa màn hình máy" : "Mở khóa màn hình máy")} của bé {device.ChildName}",
                    CreatedAt = DateTime.UtcNow
                });
                await _context.SaveChangesAsync();
            }

            var statusText = isLocked ? "đã được KHÓA từ xa" : "đã được MỞ KHÓA";
            return Ok(new { Status = true, Message = $"Thiết bị của bé {device.ChildName} {statusText}!", IsLocked = device.IsLocked });
        }

        // POST: api/ChildDevices/location (Cập nhật vị trí GPS và cảm biến thời gian thực)
        [HttpPost("location")]
        public async Task<IActionResult> UpdateLocation([FromBody] UpdateLocationDto dto)
        {
            var device = await _context.ChildDevices.FindAsync(dto.ChildDeviceId);
            if (device == null) return NotFound(new { Message = "Không tìm thấy thiết bị" });

            device.CurrentLatitude = dto.Latitude;
            device.CurrentLongitude = dto.Longitude;
            if (!string.IsNullOrEmpty(dto.Address)) device.CurrentAddress = dto.Address;
            if (dto.NoiseDecibel.HasValue) device.CurrentNoiseLevel = dto.NoiseDecibel.Value;
            if (dto.BatteryLevel.HasValue) device.BatteryLevel = dto.BatteryLevel.Value;
            device.LastLocationTime = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return Ok(new { Status = true, Message = "Vị trí và cảm biến đã được đồng bộ thời gian thực" });
        }

        // POST: api/ChildDevices/pair (Ghép đôi thiết bị qua mã QR Code)
        [HttpPost("pair")]
        public async Task<IActionResult> PairDevice([FromBody] PairRequestDto request)
        {
            var device = await _context.ChildDevices.FirstOrDefaultAsync(d => d.DeviceCode == request.DeviceCode);
            if (device == null)
            {
                return NotFound(new { Status = false, Message = "Mã QR / Mã thiết bị không hợp lệ!" });
            }

            if (!string.IsNullOrEmpty(request.ParentId))
            {
                device.ParentId = request.ParentId;
                await _context.SaveChangesAsync();
            }

            return Ok(new
            {
                Status = true,
                Message = $"Ghép đôi thiết bị thành công với bé {device.ChildName}!",
                Device = device
            });
        }

        // DELETE: api/ChildDevices/5 (Xóa thiết bị)
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteDevice(int id)
        {
            var device = await _context.ChildDevices.FindAsync(id);
            if (device == null) return NotFound(new { Message = "Không tìm thấy thiết bị" });

            if (!string.IsNullOrEmpty(device.ParentId))
            {
                _context.ParentAuditLogs.Add(new ParentAuditLog
                {
                    ParentId = device.ParentId,
                    ParentName = "Phụ huynh",
                    ActionType = "DELETE_DEVICE",
                    TargetName = device.DeviceName,
                    Details = $"Ngắt kết nối và xóa thiết bị: {device.DeviceName} của bé {device.ChildName}",
                    CreatedAt = DateTime.UtcNow
                });
            }

            _context.ChildDevices.Remove(device);
            await _context.SaveChangesAsync();

            return Ok(new { Status = true, Message = "Đã ngắt kết nối và xóa thiết bị thành công" });
        }
    }

    public class PairRequestDto
    {
        public string DeviceCode { get; set; } = string.Empty;
        public string? ParentId { get; set; }
    }
}
