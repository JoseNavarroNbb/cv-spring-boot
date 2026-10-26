package com.carlosnb.cv_backend.repository;

import com.carlosnb.cv_backend.entity.EventoCv;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface EventoCvRepository extends JpaRepository<EventoCv, Long> {
}