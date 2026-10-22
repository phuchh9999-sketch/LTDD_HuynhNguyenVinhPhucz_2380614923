using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using _2380614923_HuynhNguyenVinhPhuc_WebAPI.Data;
using _2380614923_HuynhNguyenVinhPhuc_WebAPI.Models;

namespace _2380614923_HuynhNguyenVinhPhuc_WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SafeZonesController : ControllerBase
    {
        private readonly KidGuardDbContext _context;

        public SafeZonesController(KidGuardDbContext context)
        {
            _context = context;
        }

        // GET: api/SafeZones/device/5
        [HttpGet("device/{deviceId}")]
        public async Task<IActionResult> GetByDevice(int deviceId)
        {
            var zones = await _context.SafeZones
                .Where(z => z.ChildDeviceId == deviceId)
                .OrderBy(z => z.Name)
                .ToListAsync();

            return Ok(zones);
        }

        // GET: api/SafeZones/5
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var zone = await _context.SafeZones.FindAsync(id);
            if (zone == null) return NotFound(new { Message = "Không tìm thấy vùng an toàn" });
            return Ok(zone);
        }

        // POST: api/SafeZones
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] SafeZone zone)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            zone.CreatedAt = DateTime.UtcNow;
            _context.SafeZones.Add(zone);
            await _context.SaveChangesAsync();

            if (!string.IsNullOrEmpty(zone.ParentId))
            {
                _context.ParentAuditLogs.Add(new ParentAuditLog
                {
                    ParentId = zone.ParentId,
                    ParentName = "Phụ huynh",
                    ActionType = "ADD_SAFE_ZONE",
                    TargetName = zone.Name,
                    Details = $"Thiết lập vùng an toàn mới: '{zone.Name}' (Bán kính {zone.RadiusMeters}m - {zone.Address})",
                    CreatedAt = DateTime.UtcNow
                });
                await _context.SaveChangesAsync();
            }

            return CreatedAtAction(nameof(GetById), new { id = zone.Id }, zone);
        }

        // PUT: api/SafeZones/5
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] SafeZone updated)
        {
            var zone = await _context.SafeZones.FindAsync(id);
            if (zone == null) return NotFound(new { Message = "Không tìm thấy vùng an toàn" });

            zone.Name = updated.Name;
            zone.Address = updated.Address;
            zone.Latitude = updated.Latitude;
            zone.Longitude = updated.Longitude;
            zone.RadiusMeters = updated.RadiusMeters;
            zone.IsActive = updated.IsActive;

            await _context.SaveChangesAsync();
            return Ok(new { Status = true, Message = "Cập nhật vùng an toàn thành công", SafeZone = zone });
        }

        // DELETE: api/SafeZones/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var zone = await _context.SafeZones.FindAsync(id);
            if (zone == null) return NotFound(new { Message = "Không tìm thấy vùng an toàn" });

            if (!string.IsNullOrEmpty(zone.ParentId))
            {
                _context.ParentAuditLogs.Add(new ParentAuditLog
                {
                    ParentId = zone.ParentId,
                    ParentName = "Phụ huynh",
                    ActionType = "DELETE_SAFE_ZONE",
                    TargetName = zone.Name,
                    Details = $"Xóa vùng an toàn: '{zone.Name}'",
                    CreatedAt = DateTime.UtcNow
                });
            }

            _context.SafeZones.Remove(zone);
            await _context.SaveChangesAsync();

            return Ok(new { Status = true, Message = "Đã xóa vùng an toàn" });
        }
    }
}
