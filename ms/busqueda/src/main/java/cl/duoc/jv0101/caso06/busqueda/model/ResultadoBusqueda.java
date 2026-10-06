package cl.duoc.jv0101.caso06.busqueda.model;

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
import java.math.BigDecimal;


@Entity
@Table(name = "resultados")
public class ResultadoBusqueda {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "El nombre es obligatorio")
    @Column(nullable = false)
    private String nombre;

    @Column
    private String proveedor;
    @Column
    private BigDecimal precio;

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

    public BigDecimal getPrecio() { return precio; }

    public void setPrecio(BigDecimal precio) { this.precio = precio; }


    @OneToMany(mappedBy = "resultadoBusqueda", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    private List<FiltroBusqueda> filtros = new ArrayList<>();

    public List<FiltroBusqueda> getFiltros() {
        return filtros;
    }

    public void setFiltros(List<FiltroBusqueda> filtros) {
        if (filtros == null) {
            return;
        }
        this.filtros = filtros;
        filtros.forEach(item -> item.setResultadoBusqueda(this));
    }

    public void addFiltroBusqueda(FiltroBusqueda item) {
        item.setResultadoBusqueda(this);
        this.filtros.add(item);
    }

    public void replaceFiltros(List<FiltroBusqueda> nuevos) {
        this.filtros.clear();
        if (nuevos != null) {
            nuevos.forEach(item -> addFiltroBusqueda(item));
        }
    }

}
