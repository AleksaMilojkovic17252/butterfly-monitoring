from rest_framework import serializers

from apps.projects.models import Project


class ProjectSerializer(serializers.ModelSerializer):
    period = serializers.SerializerMethodField()
    # Annotated by the view. Counts live transects once Transect exists (T021).
    transect_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = Project
        fields = [
            "id",
            "name",
            "description",
            "start_date",
            "end_date",
            "period",
            "default_crs",
            "active",
            "transect_count",
            "server_version",
            "deleted_at",
        ]
        read_only_fields = fields

    def get_period(self, project) -> dict:
        return {"start_date": project.start_date, "end_date": project.end_date}
