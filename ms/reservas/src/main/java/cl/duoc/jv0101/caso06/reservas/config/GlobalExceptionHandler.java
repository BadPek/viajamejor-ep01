package cl.duoc.jv0101.caso06.reservas.config;

import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.NoSuchElementException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> manejarValidacion(MethodArgumentNotValidException ex) {
        Map<String, String> detalles = new LinkedHashMap<>();
        ex.getBindingResult().getFieldErrors()
                .forEach(err -> detalles.put(err.getField(), err.getDefaultMessage()));
        return ResponseEntity.badRequest()
                .body(cuerpo(HttpStatus.BAD_REQUEST, "Error de validación", detalles));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String, Object>> manejarJsonInvalido(HttpMessageNotReadableException ex) {
        return ResponseEntity.badRequest()
                .body(cuerpo(HttpStatus.BAD_REQUEST, "JSON inválido o malformado", null));
    }

    @ExceptionHandler(NoSuchElementException.class)
    public ResponseEntity<Map<String, Object>> manejarNoEncontrado(NoSuchElementException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(cuerpo(HttpStatus.NOT_FOUND, ex.getMessage(), null));
    }

    private Map<String, Object> cuerpo(HttpStatus status, String mensaje, Object detalles) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("timestamp", OffsetDateTime.now().toString());
        body.put("status", status.value());
        body.put("error", status.getReasonPhrase());
        body.put("message", mensaje);
        if (detalles != null) {
            body.put("details", detalles);
        }
        return body;
    }
}
