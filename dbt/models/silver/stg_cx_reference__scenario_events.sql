-- Silver : cx_reference__scenario_events (données complémentaires), typée et renommée, sans règle métier.
select
    {{ to_date('event_date') }} as event_date,
    {{ txt('scope') }}          as scope,
    {{ txt('event') }}          as event,
    {{ txt('description') }}    as description,
    _source
from {{ source('bronze', 'cx_reference__scenario_events') }}
