-- Catalogue des formations sécurité.
select
    course_code,
    course_title,
    category          as course_category,
    duration_hours,
    validity_months,
    required_for
from {{ ref('stg_cx_ehs__training_catalog') }}
