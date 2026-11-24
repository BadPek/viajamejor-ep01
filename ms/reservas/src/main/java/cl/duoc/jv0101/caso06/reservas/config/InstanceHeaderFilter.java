package cl.duoc.jv0101.caso06.reservas.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.InetAddress;
import java.net.UnknownHostException;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class InstanceHeaderFilter extends OncePerRequestFilter {

    private final String hostname;

    public InstanceHeaderFilter() {
        String resolved;
        try {
            resolved = InetAddress.getLocalHost().getHostName();
        } catch (UnknownHostException ex) {
            resolved = "unknown-host";
        }
        this.hostname = resolved;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain) throws ServletException, IOException {
        response.setHeader("X-Instance-Host", hostname);
        response.setHeader("X-Service-Name", "reservas-svc");
        filterChain.doFilter(request, response);
    }
}
