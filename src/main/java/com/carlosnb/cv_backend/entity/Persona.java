package com.carlosnb.cv_backend.entity;

import com.fasterxml.jackson.annotation.JsonManagedReference;
import jakarta.persistence.*;
import lombok.Data;
import java.util.List;

@Data
@Entity
@Table(name = "persona")
public class Persona {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    private String nombre;
    @Column(name = "apellido_paterno")
    private String apellidoPaterno;
    @Column(name = "apellido_materno")
    private String apellidoMaterno;
    @Column(name = "nombre_completo", insertable = false, updatable = false)
    private String nombreCompleto;
    @Column(name = "titulo_profesional")
    private String tituloProfesional;

    // Relaciones: Una persona tiene muchas cosas
    @OneToMany(mappedBy = "persona", cascade = CascadeType.ALL)
    @JsonManagedReference // Evita ciclo infinito en JSON
    private List<Experience> experiencias;

    @OneToMany(mappedBy = "persona", cascade = CascadeType.ALL)
    @JsonManagedReference
    private List<Proyecto> proyectos;
}