/**
 * @description Teste les filtres de CaseSelector, ses garde-fous et le plafond de résultats.
 * @author MM
 * @group EG Manufacturing
 * @last modified by MM on 05-11-2026
 **/
@IsTest
private class CaseSelectorTest {

    /**
     * Crée les enregistrements de base partagés avant chaque méthode de test.
     * Le Subject du Case contient « Generator », le mot-clé des scénarios de recherche positifs.
     **/
    @TestSetup
    static void setupData() {
         // Créer d'abord le parent, car le sélecteur et les Cases de test sont associés à cet Account.
         Account account = TestDataFactory.createTestAccount();
         // La méthode utilitaire insère un Case au Subject connu et le relie à l'Account.
         TestDataFactory.createTestCase(account.Id);
    }

    /**
     * Vérifie la recherche par sous-chaîne, le nettoyage de la saisie et la réponse sous la limite.
     **/
    @IsTest
    static void testGetCasesByAccountIdAndSubjectSuccess() {
        // Arrange : récupérer l'Account isolé créé par @TestSetup.
        Account account = getTestAccount();

        // Act : ouvrir une fenêtre de mesure des governor limits autour de l'appel au sélecteur.
        Test.startTest();
        // Entourer le mot-clé d'espaces pour tester l'opération trim du sélecteur.
        CaseSearchResult result =
            CaseSelector.getCasesByAccountIdAndSubject(account.Id, ' Generator ');
        Test.stopTest();

        // Assert : vérifier la ligne renvoyée, son Subject et l'absence de dépassement.
        // Une seule correspondance est attendue et l'indicateur de dépassement doit rester false.
        Assert.areEqual(1, result.cases.size(), 'The selector should find the matching Case.');
        Assert.areEqual(
            'Test Generator Breakdown',
            result.cases[0].Subject,
            'The selector should return the matching subject.'
        );
        Assert.isFalse(result.limitReached, 'A result below the limit should not signal truncation.');
    }

    /**
     * Vérifie qu'une requête valide sans Subject correspondant renvoie une liste vide, et non une erreur.
     **/
    @IsTest
    static void testGetCasesByAccountIdAndSubjectNoMatch() {
        // Arrange : utiliser un Account valide et un mot-clé absent du Subject du Case de test.
        Account account = getTestAccount();

        // Act : exécuter une requête valide qui doit renvoyer zéro correspondance.
        Test.startTest();
        CaseSearchResult result =
            CaseSelector.getCasesByAccountIdAndSubject(account.Id, 'No matching subject');
        Test.stopTest();

        // Assert : l'absence de correspondance donne une liste vide, sans erreur ni troncature.
        // Aucun Case ne correspond ; la liste est vide et aucune limite n'a été dépassée.
        Assert.areEqual(0, result.cases.size(), 'A non-matching search should return no Cases.');
        Assert.isFalse(result.limitReached, 'An empty result should not signal truncation.');
    }

    /**
     * Vérifie que le garde-fou sur l'ID de l'Account sort de la méthode avant l'exécution du SOQL.
     **/
    @IsTest
    static void testGetCasesByAccountIdAndSubjectWithNullAccountId() {
        // Act : omettre l'ID parent pour tester la première condition du garde-fou.
        Test.startTest();
        CaseSearchResult result =
            CaseSelector.getCasesByAccountIdAndSubject(null, 'Generator');
        Test.stopTest();

        // Assert : le DTO initialisé est vide et n'indique aucune troncature.
        // Lorsque l'ID parent manque, le DTO préinitialisé est renvoyé sans modification.
        Assert.areEqual(0, result.cases.size(), 'A null Account ID should return no Cases.');
        Assert.isFalse(result.limitReached, 'A null Account ID should not signal truncation.');
    }

    /**
     * Vérifie que String.isBlank() rejette les termes null et ceux composés uniquement d'espaces.
     **/
    @IsTest
    static void testGetCasesByAccountIdAndSubjectWithBlankTerm() {
        // Arrange : conserver un Account valide afin de tester spécifiquement les termes invalides.
        Account account = getTestAccount();

        // Act : tester les termes null et composé d'espaces dans la même fenêtre d'exécution.
        Test.startTest();
        CaseSearchResult nullTermResult =
            CaseSelector.getCasesByAccountIdAndSubject(account.Id, null);
        CaseSearchResult blankTermResult =
            CaseSelector.getCasesByAccountIdAndSubject(account.Id, '   ');
        Test.stopTest();

        // Assert : les deux parcours du garde-fou renvoient le même DTO vide et non tronqué.
        // Les deux valeurs déclenchent le garde-fou et produisent la réponse vide standard.
        Assert.areEqual(0, nullTermResult.cases.size(), 'A null search term should return no Cases.');
        Assert.isFalse(nullTermResult.limitReached, 'A null search term should not signal truncation.');
        Assert.areEqual(0, blankTermResult.cases.size(), 'A blank search term should return no Cases.');
        Assert.isFalse(blankTermResult.limitReached, 'A blank search term should not signal truncation.');
    }

    /**
     * Vérifie que 100 correspondances exactement ne déclenchent pas l'indicateur de dépassement.
     **/
    @IsTest
    static void testGetCasesByAccountIdAndSubjectAtExactLimit() {
        // Arrange : le Case initial et les 99 Cases insérés donnent exactement 100 correspondances.
        Account account = getTestAccount();
        insertCases(account.Id, 99); // Le Case du setup plus 99 enregistrements supplémentaires donne 100.

        // Act : appeler le sélecteur à la limite exacte d'affichage.
        Test.startTest();
        CaseSearchResult result =
            CaseSelector.getCasesByAccountIdAndSubject(account.Id, 'Generator');
        Test.stopTest();

        // Assert : aucune 101e correspondance n'existe ; toutes les lignes tiennent et limitReached reste false.
        Assert.areEqual(100, result.cases.size(), 'The selector should return all 100 matching Cases.');
        Assert.isFalse(result.limitReached, 'Exactly 100 matches should not signal truncation.');
    }

    /**
     * Vérifie que plus de 100 correspondances sont plafonnées et signalées à l'appelant.
     **/
    @IsTest
    static void testGetCasesByAccountIdAndSubjectOverLimit() {
        // Arrange : le Case initial et les 100 Cases insérés donnent 101 correspondances.
        Account account = getTestAccount();
        insertCases(account.Id, 100); // Le Case du setup plus 100 enregistrements supplémentaires donne 101.

        // Act : appeler le sélecteur au-delà de la limite d'affichage.
        Test.startTest();
        CaseSearchResult result =
            CaseSelector.getCasesByAccountIdAndSubject(account.Id, 'Generator');
        Test.stopTest();

        // Assert : seules 100 lignes sont renvoyées et l'indicateur signale la correspondance omise.
        Assert.areEqual(100, result.cases.size(), 'The selector should return no more than 100 Cases.');
        Assert.isTrue(result.limitReached, 'More than 100 matches should signal truncation.');
    }

    /**
     * Insère les enregistrements de test correspondants en une opération DML pour les scénarios de limite.
     **/
    private static void insertCases(Id accountId, Integer numberOfCases) {
        List<Case> casesToInsert = new List<Case>();
        // Construire tous les enregistrements en mémoire avant une insertion unique, selon la pratique bulk DML.
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
     * Récupère l'Account créé par @TestSetup dans le contexte de données isolé de ce test.
     **/
    private static Account getTestAccount() {
        return [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
    }
}
