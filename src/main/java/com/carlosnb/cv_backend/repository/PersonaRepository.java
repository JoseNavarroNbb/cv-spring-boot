package com.carlosnb.cv_backend.repository;

import com.carlosnb.cv_backend.entity.Persona;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PersonaRepository extends JpaRepository<Persona, Integer> {

    // 1. Traemos la Persona con Experiencias (y su Empresa)
    @Query("SELECT DISTINCT p FROM Persona p " +
           "LEFT JOIN FETCH p.experiencias e " +
           "LEFT JOIN FETCH e.empresa " +
           "WHERE p.id = :id")
    Optional<Persona> findPersonaWithExperiencias(@Param("id") Integer id);

    // 2. Traemos la Persona con Proyectos
    @Query("SELECT DISTINCT p FROM Persona p " +
           "LEFT JOIN FETCH p.proyectos " +
           "WHERE p.id = :id")
    Optional<Persona> findPersonaWithProyectos(@Param("id") Integer id);
}