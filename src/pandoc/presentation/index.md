---
title: "Clean architecture"
subtitle: "With Symfony"
author: "DG ECFIN R3 - Gilles Demaret"
institute: "European Commission"
date: "February 2023"
documentclass: "beamer"
beamer: true
theme: "ec"
notes: false
toc: false
---

# Introduction

> - Présentation de l'architecture sur laquelle se repose 3 de nos projets :
>   - CSR (Country Specific Recommendations)
>   - RRF (Recovery and Resilience Facility)
>   - RAFT (Submodule of RRF)

## Pourquoi la clean architecture ?

> - Pourquoi la clean architecture ? Pourquoi une architecture tout court ?
>   - Pour palier à des problèmes récurrents sur des projets informatiques:
>     - Code spaghetti
>     - Code business éparpillé entre les controllers, les services, les
>       managers et même les views
>     - Des services ou manager qui ont trop de responsabilités
>     - ...
>   - Pour faciliter l'évolution de nos projets, leur maintenance
>   - Pour rendre notre métier plus intéressant et plus enrichissant

## Qui ? Quand ?

> - Qui ?
>   - Présenté par Robert C. Martin (Uncle Bob) en 2012
> - Combine plusieurs variantes architecturales
>   - **Hexagonal** architecture
>   - **Onion** architecture
>   - **Screaming** architecture
>   - **MVP** (Model View Presenter)
>   - Use Case driven approach
>   - SOLID

# Objectif

> - L'objectif est:
>   - De diviser le code en briques, chaque brique traitant d'un sujet.
>   - Les briques sont elles-même divisées en couches.
>   - Chaque brique comporte au moins une couche d'accès au business et une
>     couche d'interfaçage permettant la connexion inter-briques.

# Avantages

> - Avantages
>   - L'indépendance vis-à-vis des frameworks : les frameworks sont alors
>     utilisés comme des outils plutôt que l'inverse
>   - L'indépendance vis-à-vis de l'interface utilisateur
>   - L'indépendance vis-à-vis de la base de données
>   - L'indépendance vis-à-vis des services tiers
>   - La granularité des tests : il est facile de cibler précisément une couche
>     / brique

\note<1>{ L'indépendance vis-à-vis des services tiers: Exemple avec Secunda soap
et rest }

# Principe

## Schéma d'uncle Bob

![Uncle Bob](src/pandoc/presentation/resources/CleanArchitectureUncleBob.jpg)

## Le domaine

![Clean architecture 02](src/pandoc/presentation/resources/schema-clean-architecture-02.png)

## Le domaine piloté et pilote

![Clean architecture 03](src/pandoc/presentation/resources/schema-clean-architecture-03.png)

## Le domaine et le monde extérieur

![Clean architecture 04](src/pandoc/presentation/resources/schema-clean-architecture-04.png)

## Vue globale

![Clean architecture 05](src/pandoc/presentation/resources/schema-clean-architecture-05.png)

# Exemple

## La request

\tiny

```php
class SwitchPhaseToExecutionRequest implements RequestInterface
{
    public Audit $audit;
}
```

\normalsize

## Le Use Case

\tiny

```php
class SwitchPhaseToExecution extends AbstractUseCaseItem
{
    public function __construct(
        private SwitchPhaseToExecutionValidator $validator,
        private AuditPhaseRepositoryInterface $auditPhaseRepository
    ) {
    }

    private function execute(
        SwitchPhaseToExecutionRequest $request
        PresenterInterface $presenter
    ):void {
        ...
        $this->response->model = $request->audit;
        $this->presenter->present($this->response);
    }
}
```

\normalsize

## La response

\tiny

```php
class ApiItemResponse implements ResponseItemInterface
{
    /**
     * @var object
     */
    public $model;

    /**
     * @var array
     */
    public $errors = [];
}
```

\normalsize

## Piloté par une commande

\tiny

```php
class SwitchAuditPhaseToExecutionCommand extends Command
{
    public function __construct(
        private AuditRepository $auditRepository,
        private SwitchPhaseToExecution $useCase,
        private SwitchPhaseToExecutionCommandPresenter $presenter,
        private CommandViewer $viewer,
    ) {
        parent::__construct();
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $audits = $this->auditRepository->findAllOnPreparationPhase();

        ...

        foreach ($audits as $audit) {
            $useCaseRequest = new SwitchPhaseToExecutionRequest();
            $useCaseRequest->audit = $audit;

            try {
                $this->useCase->execute($useCaseRequest, $this->presenter);

                return $this->viewer->generateView($this->presenter->viewModel(), Command::SUCCESS);
            } catch (Throwable $exception) {
                return $this->viewer->generateView($this->presenter->viewModel(), Command::FAILURE);
            }
        }
    }
}
```

\normalsize

\note<1>{ On a pris la liberté d'utiliser l'injection de dépendances de Symfony
par pragmatisme. Mais rien ne nous empêche d'en utiliser un autre voir de
développer notre propre injecteur mais dans notre cas il n'y aurait pas de plus
value}

# Conclusion

> - Avantages ?
> - Coût ? Inconvénients ?

\note<1>{ Revenir aux avantages }

# Sources

- Clean Architecture: A Craftsman's Guide to Software Structure and Design: A
  Craftsman's Guide to Software Structure and Design (Robert C. Martin Series)
- https://youtu.be/LTxJFQ6xmzM (Présentation par Nicolas De Boose)
- https://www.adimeo.com/blog/forum-php-2019-clean-architecture
- https://www.adimeo.com/blog/forum-php-2019-developpement-pragmatique
