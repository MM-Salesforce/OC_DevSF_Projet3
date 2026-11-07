/**
 * @description Teste le point d'entrée Apex appelé par le LWC accountCasesSearcher.
 * @author MM
 * @group EG Manufacturing
 * @last modified by MM on 05-11-2026
 **/
@IsTest
private class AccountCasesControllerTest {

    /**
     * Crée un jeu de données de base isolé pour chaque méthode de test de cette classe.
     **/
    @TestSetup
    static void setupData() {
        // Créer l'Account parent avant le Case qui lui sera rattaché et recherché.
        Account account = TestDataFactory.createTestAccount();
        TestDataFactory.createTestCase(account.Id);
    }

    /**
     * Vérifie que le contrôleur transmet une chaîne vide au garde-fou du sélecteur.
     **/
    @IsTest
    static void testFindCasesBySubjectWithEmptyTerm() {
        // Arrange : utiliser un Account valide afin de tester uniquement le terme vide.
        Account account = getTestAccount();

        // Act : appeler le point d'entrée Apex utilisé par le LWC.
        Test.startTest();
        CaseSearchResult result =
            AccountCasesController.findCasesBySubject(account.Id, '');
        Test.stopTest();

        // Assert : une saisie vide est un résultat de validation ; le contrôleur renvoie un DTO vide.
        Assert.areEqual(0, result.cases.size(), 'An empty search term should return no Cases.');
        Assert.isFalse(result.limitReached, 'An empty search term should not signal truncation.');
    }

    /**
     * Vérifie qu'une saisie composée uniquement d'espaces n'élargit pas la recherche.
     **/
    @IsTest
    static void testFindCasesBySubjectWithWhitespaceTerm() {
        // Arrange : fournir un Account valide avec un terme de recherche composé d'espaces.
        Account account = getTestAccount();

        // Act : transmettre les espaces via le contrôleur jusqu'au garde-fou du sélecteur.
        Test.startTest();
        CaseSearchResult result =
            AccountCasesController.findCasesBySubject(account.Id, '   ');
        Test.stopTest();

        // Assert : String.isBlank() dans le sélecteur reconnaît cette saisie comme vide.
        Assert.areEqual(0, result.cases.size(), 'A whitespace-only term should return no Cases.');
        Assert.isFalse(result.limitReached, 'A whitespace-only term should not signal truncation.');
    }

    /**
     * Vérifie que le contrôleur renvoie au LWC la réponse réussie du sélecteur.
     **/
    @IsTest
    static void testFindCasesBySubjectSuccess() {
        // Arrange : @TestSetup a créé un Case dont le Subject contient « Generator ».
        Account account = getTestAccount();

        // Act : appeler la même méthode du contrôleur que celle importée par le LWC.
        Test.startTest();
        CaseSearchResult result =
            AccountCasesController.findCasesBySubject(account.Id, 'Generator');
        Test.stopTest();

        // Assert : le contrôleur conserve le Case correspondant et l'indicateur de limite.
        Assert.areEqual(1, result.cases.size(), 'The controller should return the matching Case.');
        Assert.isFalse(result.limitReached, 'A result below the limit should not signal truncation.');
    }

    /**
     * Vérifie qu'une recherche sans correspondance renvoie une réponse vide sans erreur.
     **/
    @IsTest
    static void testFindCasesBySubjectNoMatch() {
        // Arrange : l'Account possède un Case, mais son Subject ne contient pas cette expression.
        Account account = getTestAccount();

        // Act : lancer une recherche valide sans enregistrement correspondant.
        Test.startTest();
        CaseSearchResult result =
            AccountCasesController.findCasesBySubject(account.Id, 'No matching subject');
        Test.stopTest();

        // Assert : un résultat vide n'est pas une erreur ; le LWC affiche son état « aucun résultat ».
        Assert.areEqual(0, result.cases.size(), 'A non-matching search should return no Cases.');
        Assert.isFalse(result.limitReached, 'An empty result should not signal truncation.');
    }

    /**
     * Vérifie que l'absence de contexte d'enregistrement renvoie la réponse vide protégée du sélecteur.
     **/
    @IsTest
    static void testFindCasesBySubjectWithNullId() {
        // Act : simuler un appel sans contexte d'enregistrement Account.
        Test.startTest();
        CaseSearchResult result =
            AccountCasesController.findCasesBySubject(null, 'Generator');
        Test.stopTest();

        // Assert : le sélecteur détecte l'ID null et renvoie le DTO vide initialisé.
        Assert.areEqual(0, result.cases.size(), 'A null Account ID should return no Cases.');
        Assert.isFalse(result.limitReached, 'A null Account ID should not signal truncation.');
    }

    /**
     * Vérifie que le contrôleur conserve le plafond et l'indicateur de dépassement pour 101 correspondances.
     **/
    @IsTest
    static void testFindCasesBySubjectLimitReached() {
        // Arrange : le Case initial et les 100 Cases ajoutés donnent 101 enregistrements correspondants.
        Account account = getTestAccount();
        insertCases(account.Id, 100); // Le Case du setup plus 100 enregistrements supplémentaires donne 101.

        // Act : exécuter le parcours contrôleur-sélecteur au-delà du plafond.
        Test.startTest();
        CaseSearchResult result =
            AccountCasesController.findCasesBySubject(account.Id, 'Generator');
        Test.stopTest();

        // Assert : le DTO renvoyé au LWC contient 100 lignes et un indicateur de dépassement à true.
        Assert.areEqual(100, result.cases.size(), 'The controller should return at most 100 Cases.');
        Assert.isTrue(result.limitReached, 'The controller should report more than 100 matches.');
    }

    /**
     * Vérifie que l'indicateur de dépassement est false pour exactement 100 enregistrements correspondants.
     **/
    @IsTest
    static void testFindCasesBySubjectAtExactLimit() {
        // Arrange : le Case initial et les 99 Cases ajoutés donnent exactement 100 correspondances.
        Account account = getTestAccount();
        insertCases(account.Id, 99); // Le Case du setup plus 99 enregistrements supplémentaires donne 100.

        // Act : exécuter le parcours contrôleur-sélecteur à la limite exacte.
        Test.startTest();
        CaseSearchResult result =
            AccountCasesController.findCasesBySubject(account.Id, 'Generator');
        Test.stopTest();

        // Assert : aucune 101e correspondance n'existe ; le contrôleur ne doit donc pas signaler de résultat omis.
        Assert.areEqual(100, result.cases.size(), 'The controller should return all 100 matching Cases.');
        Assert.isFalse(result.limitReached, 'Exactly 100 matches should not signal truncation.');
    }

    /**
     * Insère le nombre demandé de Cases correspondants en une seule opération DML en lot.
     **/
    private static void insertCases(Id accountId, Integer numberOfCases) {
        List<Case> casesToInsert = new List<Case>();
        // Préparer toute la collection en mémoire, puis effectuer une seule insertion DML en lot.
        for (Integer i = 0; i < numberOfCases; i++) {
            casesToInsert.add(new Case(
                AccountId = accountId,
                Subject = 'Generator additional case ' + i,
                Status = 'New',
                Priority = 'High'
            ));
        }
        insert casesToInsert;
    }

    /**
     * Récupère l'Account créé par la méthode @TestSetup de cette classe.
     **/
    private static Account getTestAccount() {
        return [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
    }
}
