package cl.duoc.jv0101.caso06.integraciones.model;

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
@Table(name = "integraciones")
public class Integracion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "El nombre es obligatorio")
    @Column(nullable = false)
    private String nombre;

    @Column
    private String proveedor;
    @Column
    private String estado;

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

    public String getProveedor() { return proveedor; }

    public void setProveedor(String proveedor) { this.proveedor = proveedor; }

    public String getEstado() { return estado; }

    public void setEstado(String estado) { this.estado = estado; }


    @OneToMany(mappedBy = "integracion", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    private List<RegistroLlamada> registros = new ArrayList<>();

    public List<RegistroLlamada> getRegistros() {
        return registros;
    }

    public void setRegistros(List<RegistroLlamada> registros) {
        if (registros == null) {
            return;
        }
        this.registros = registros;
        registros.forEach(item -> item.setIntegracion(this));
    }

    public void addRegistroLlamada(RegistroLlamada item) {
        item.setIntegracion(this);
        this.registros.add(item);
    }

    public void replaceRegistros(List<RegistroLlamada> nuevos) {
        this.registros.clear();
        if (nuevos != null) {
            nuevos.forEach(item -> addRegistroLlamada(item));
        }
    }

}
