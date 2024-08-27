show tables;

DROP TABLE product_bool;
CREATE TABLE product_bool (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    is_electronics BOOLEAN,  -- 가전제품 여부
    is_furniture BOOLEAN,    -- 가구 여부
    is_seasonal BOOLEAN,     -- 계절성 여부
    -- 생성된 컬럼으로 비트맵을 표현 ((2)000 로 처리)
    category_bitmap INT GENERATED ALWAYS AS (
        (is_electronics << 2) | (is_furniture << 1) | is_seasonal      ) STORED,
    INDEX idx_category_bitmap (category_bitmap) -- 비트맵 인덱스
);

SHOW CREATE TABLE product_bool;

CREATE TABLE `product_bool` (
  `product_id` int NOT NULL,
  `is_electronics` tinyint(1) DEFAULT NULL,
  `is_furniture` tinyint(1) DEFAULT NULL,
  `is_seasonal` tinyint(1) DEFAULT NULL,
  `category_bitmap` int GENERATED ALWAYS AS ((((`is_electronics` << 2) | (`is_furniture` << 1)) | `is_seasonal`)) STORED,
  PRIMARY KEY (`product_id`),
  KEY `idx_category_bitmap` (`category_bitmap`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DELIMITER $$

CREATE PROCEDURE generate_product_bool_data(IN num_records INT)
BEGIN
    DECLARE counter INT DEFAULT 1;

    WHILE counter <= num_records DO
        INSERT INTO product_bool (is_electronics, is_furniture, is_seasonal)
        VALUES (
            (RAND() < 0.5), -- 랜덤하게 TRUE 또는 FALSE를 생성
            (RAND() < 0.5),
            (RAND() < 0.5)
        );
        SET counter = counter + 1;
    END WHILE;
END$$

DELIMITER ;

CALL generate_product_bool_data(10000);

-- 0 ~ 7
-- 0 : 0b000 가전X, 가구X, 계절X
-- 7 : 0b111 가전X, 가구X, 계절X

EXPLAIN SELECT * FROM product_bool
WHERE is_electronics = TRUE  -- 100
AND is_seasonal = TRUE;      -- 001

-- Bitmap 연산 (컬럼 비교연산만 절약, 인덱스 사용 불가)
EXPLAIN SELECT *
FROM product_bool
WHERE (category_bitmap & 0b101) = 0b101;

EXPLAIN SELECT *
FROM product_bool
WHERE (category_bitmap & 5) = 5;

-- In 연산 (인덱스 사용 가능하지만 filtering 비교연산)
EXPLAIN SELECT * FROM product_bool
WHERE category_bitmap in (7, 5)
-- order by category_bitmap desc
;

EXPLAIN SELECT * FROM product_bool
WHERE category_bitmap = 5
UNION ALL
SELECT * FROM product_bool
WHERE category_bitmap = 7;
