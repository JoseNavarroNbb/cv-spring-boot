package com.carlosnb.cv_backend.repository;

import com.carlosnb.cv_backend.entity.CategoriaHabilidad;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CategoriaHabilidadRepository extends JpaRepository<CategoriaHabilidad, Short> {
}