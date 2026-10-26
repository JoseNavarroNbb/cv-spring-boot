package com.carlosnb.cv_backend.repository;

import com.carlosnb.cv_backend.entity.SesionVisita;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SesionVisitaRepository extends JpaRepository<SesionVisita, Long> {
}