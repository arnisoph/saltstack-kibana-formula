#!jinja|yaml

{% set datamap = salt['formhelper.get_defaults']('kibana', saltenv) %}

# SLS includes/ excludes
include: {{ datamap.sls_include|default([]) }}
extend: {{ datamap.sls_extend|default({}) }}

{% if 'docroot_basedir' in datamap.config %}
  {% set f = datamap['config']['docroot_basedir'] %}
kibana_docroot_basedir:
  file:
    - directory
    - name: {{ f.path }}
    - user: {{ datamap.user.name|default(f.user) }}
    - group: {{ datamap.group.name|default(f.group) }}
    - mode: {{ f.mode|default(755) }}
{% endif %}

{% for id, instance in datamap.instances|default({})|dictsort %}
kibana_instance_{{ id }}_dir:
  file:
    - directory
    - name: {{ datamap.config.docroot_basedir.path }}/{{ id }}
    - user: {{ datamap.user.name }}
    - group: {{ datamap.group.name }}
    - mode: {{ f.mode|default(755) }}
    - recurse:
      - user
      - group

  {% for v_id, version in instance.versions|default({})|dictsort %}
kibana_instance_{{ id }}:
  archive:
    - extracted
    - name: {{ datamap.config.docroot_basedir.path }}/{{ id }}
    - source: {{ version.source }}
    - source_hash: {{ version.source_checksum }}
    - keep: True
    - archive_format: {{ version.source_archive_format|default('tar') }}
    - if_missing: {{ datamap.config.docroot_basedir.path }}/{{ id }}/{{ version.version|default(v_id) }}
    - require_in:
      - file: kibana_instance_{{ id }}_dir
  {% endfor %}

  {% if 'current_ver' in instance %}
kibana_instance_{{ id }}_current_ver:
  file:
    - symlink
    - name: {{ datamap.config.docroot_basedir.path }}/{{ id }}/current
    - target: {{ datamap.config.docroot_basedir.path }}/{{ id }}/{{ instance.current_ver }}
    - user: {{ datamap.user.name }}
    - group: {{ datamap.group.name }}
  {% endif %}
{% endfor %}
