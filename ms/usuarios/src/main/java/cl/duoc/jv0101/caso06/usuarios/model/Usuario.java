package cl.duoc.jv0101.caso06.usuarios.model;

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
@Table(name = "usuarios")
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "El nombre es obligatorio")
    @Column(nullable = false)
    private String nombre;

    @Column
    private String email;
    @Column
    private String nivel;

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

    public String getEmail() { return email; }

    public void setEmail(String email) { this.email = email; }

    public String getNivel() { return nivel; }

    public void setNivel(String nivel) { this.nivel = nivel; }


    @OneToMany(mappedBy = "usuario", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    private List<Direccion> direcciones = new ArrayList<>();

    public List<Direccion> getDirecciones() {
        return direcciones;
    }

    public void setDirecciones(List<Direccion> direcciones) {
        if (direcciones == null) {
            return;
        }
        this.direcciones = direcciones;
        direcciones.forEach(item -> item.setUsuario(this));
    }

    public void addDireccion(Direccion item) {
        item.setUsuario(this);
        this.direcciones.add(item);
    }

    public void replaceDirecciones(List<Direccion> nuevos) {
        this.direcciones.clear();
        if (nuevos != null) {
            nuevos.forEach(item -> addDireccion(item));
        }
    }

}
