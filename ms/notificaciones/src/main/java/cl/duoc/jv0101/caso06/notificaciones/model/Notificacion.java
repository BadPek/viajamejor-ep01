package cl.duoc.jv0101.caso06.notificaciones.model;

import jakarta.persistence.CascadeType;
import jakarta.persistence.FetchType;
import jakarta.persistence.OneToMany;
import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;


@Entity
@Table(name = "notificaciones")
public class Notificacion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "El nombre es obligatorio")
    @Column(nullable = false)
    private String nombre;

    @Column
    private String tipo;
    @Column
    private String canal;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getTipo() { return tipo; }

    public void setTipo(String tipo) { this.tipo = tipo; }

    public String getCanal() { return canal; }

    public void setCanal(String canal) { this.canal = canal; }


    @OneToMany(mappedBy = "notificacion", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    private List<EnvioNotificacion> envios = new ArrayList<>();

    public List<EnvioNotificacion> getEnvios() {
        return envios;
    }

    public void setEnvios(List<EnvioNotificacion> envios) {
        if (envios == null) {
            return;
        }
        this.envios = envios;
        envios.forEach(item -> item.setNotificacion(this));
    }

    public void addEnvioNotificacion(EnvioNotificacion item) {
        item.setNotificacion(this);
        this.envios.add(item);
    }

    public void replaceEnvios(List<EnvioNotificacion> nuevos) {
        this.envios.clear();
        if (nuevos != null) {
            nuevos.forEach(item -> addEnvioNotificacion(item));
        }
    }

}
