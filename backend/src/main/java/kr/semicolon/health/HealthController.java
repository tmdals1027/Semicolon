package kr.semicolon.health;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {

    @GetMapping("/api/health")
    public HealthResponse health() {
        return new HealthResponse("UP", "semicolon-backend");
    }

    public record HealthResponse(String status, String service) {
    }
}
