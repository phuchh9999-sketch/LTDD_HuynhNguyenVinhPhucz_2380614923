using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using _2380614923_HuynhNguyenVinhPhuc_WebAPI.Data;
using _2380614923_HuynhNguyenVinhPhuc_WebAPI.Models;

namespace _2380614923_HuynhNguyenVinhPhuc_WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SecurityAlertsController : ControllerBase
    {
        private readonly KidGuardDbContext _context;

        public SecurityAlertsController(KidGuardDbContext context)
        {
            _context = context;
        }

        // GET: api/SecurityAlerts
        [HttpGet]
        public async Task<IActionResult> GetAlerts([FromQuery] int? deviceId, [FromQuery] bool? isResolved)
        {
            var query = _context.SecurityAlerts.AsQueryable();

            if (deviceId.HasValue)
            {
                query = query.Where(a => a.ChildDeviceId == deviceId.Value);
            }

            if (isResolved.HasValue)
            {
                query = query.Where(a => a.IsResolved == isResolved.Value);
            }

            var alerts = await query
                .OrderByDescending(a => a.CreatedAt)
                .ToListAsync();

            return Ok(alerts);
        }

        // GET: api/SecurityAlerts/5
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var alert = await _context.SecurityAlerts.FindAsync(id);
            if (alert == null) return NotFound(new { Message = "Không tìm thấy cảnh báo" });
            return Ok(alert);
        }

        // POST: api/SecurityAlerts/trigger (Kích hoạt cảnh báo từ thiết bị trẻ em: SOS, Âm thanh bất thường, Rơi vỡ)
        [HttpPost("trigger")]
        public async Task<IActionResult> TriggerAlert([FromBody] TriggerAlertDto dto)
        {
            var device = await _context.ChildDevices.FindAsync(dto.ChildDeviceId);
            var childName = device != null ? device.ChildName : "Trẻ em";

            var alert = new SecurityAlert
            {
                ChildDeviceId = dto.ChildDeviceId,
                ChildName = childName,
                AlertType = dto.AlertType,
                Title = dto.Title,
                Description = dto.Description,
                Latitude = dto.Latitude != 0 ? dto.Latitude : (device?.CurrentLatitude ?? 10.776889),
                Longitude = dto.Longitude != 0 ? dto.Longitude : (device?.CurrentLongitude ?? 106.700806),
                NoiseDecibel = dto.NoiseDecibel,
                Severity = dto.Severity,
                IsResolved = false,
                CreatedAt = DateTime.UtcNow
            };

            _context.SecurityAlerts.Add(alert);

            // Cập nhật tọa độ và tiếng ồn mới nhất cho thiết bị
            if (device != null)
            {
                device.CurrentLatitude = alert.Latitude;
                device.CurrentLongitude = alert.Longitude;
                if (dto.NoiseDecibel > 0) device.CurrentNoiseLevel = dto.NoiseDecibel;
                device.LastLocationTime = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Status = true,
                Message = $"Đã phát tín hiệu cảnh báo '{alert.Title}' khẩn cấp tới Phụ huynh và Đội ngũ Giám sát!",
                Alert = alert
            });
        }

        // PUT: api/SecurityAlerts/5/resolve (Đánh dấu đã xử lý)
        [HttpPut("{id}/resolve")]
        public async Task<IActionResult> ResolveAlert(int id)
        {
            var alert = await _context.SecurityAlerts.FindAsync(id);
            if (alert == null) return NotFound(new { Message = "Không tìm thấy cảnh báo" });

            alert.IsResolved = true;
            await _context.SaveChangesAsync();

            return Ok(new { Status = true, Message = "Đã xử lý xong cảnh báo an toàn", Alert = alert });
        }

        // DELETE: api/SecurityAlerts/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var alert = await _context.SecurityAlerts.FindAsync(id);
            if (alert == null) return NotFound(new { Message = "Không tìm thấy cảnh báo" });

            _context.SecurityAlerts.Remove(alert);
            await _context.SaveChangesAsync();

            return Ok(new { Status = true, Message = "Đã xóa bản ghi cảnh báo" });
        }
    }
}
