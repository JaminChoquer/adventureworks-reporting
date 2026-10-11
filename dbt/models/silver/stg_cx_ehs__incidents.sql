-- Silver : cx_ehs__incidents (données complémentaires), typée et renommée, sans règle métier.
select
    {{ txt('incident_id') }}                       as incident_id,
    {{ txt('event_type') }}                        as event_type,
    {{ to_datetime('occurred_at') }}               as occurred_at,
    {{ to_datetime('reported_at') }}               as reported_at,
    {{ to_int('location_id') }}                    as location_id,
    {{ txt('work_center') }}                       as work_center,
    {{ to_int('shift_id') }}                       as shift_id,
    {{ txt('worker_type') }}                       as worker_type,
    {{ to_int('injured_business_entity_id') }}     as injured_business_entity_id,
    {{ to_int('reported_by_business_entity_id') }} as reported_by_business_entity_id,
    {{ txt('injury_nature') }}                     as injury_nature,
    {{ txt('body_part') }}                         as body_part,
    {{ txt('activity') }}                          as activity,
    {{ txt('root_cause_category') }}               as root_cause_category,
    {{ txt('severity_potential') }}                as severity_potential,
    {{ to_int('days_lost') }}                      as days_lost,
    {{ to_int('days_restricted') }}                as days_restricted,
    {{ txt('description') }}                       as description,
    {{ txt('status') }}                            as status,
    {{ to_datetime('closed_at') }}                 as closed_at,
    _source
from {{ source('bronze', 'cx_ehs__incidents') }}
