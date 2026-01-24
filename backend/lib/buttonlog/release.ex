defmodule ButtonLog.Release do
  @moduledoc """
  Release tasks for running in production without Mix.

  These functions are called via:
    bin/buttonlog eval "ButtonLog.Release.migrate()"
  """

  @app :buttonlog

  @doc """
  Runs all pending database migrations.
  """
  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  @doc """
  Rolls back the last migration.
  """
  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  @doc """
  Seeds the database with initial data.
  """
  def seed do
    load_app()

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, fn _repo ->
          # Run the seeds file
          seed_file = Application.app_dir(@app, "priv/repo/seeds.exs")

          if File.exists?(seed_file) do
            Code.eval_file(seed_file)
          end
        end)
    end
  end

  @doc """
  Returns current migration status.
  """
  def migration_status do
    load_app()

    for repo <- repos() do
      {:ok, status, _} =
        Ecto.Migrator.with_repo(repo, fn repo ->
          Ecto.Migrator.migrations(repo)
        end)

      {repo, status}
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
