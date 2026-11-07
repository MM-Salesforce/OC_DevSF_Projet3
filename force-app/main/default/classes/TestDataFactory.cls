/**
 * @description Crée des enregistrements de test partagés par les tests unitaires Apex.
 * @author MM
 * @group EG Manufacturing
 * @last modified by MM on 05-11-2026
 **/
@IsTest
public class TestDataFactory {

    /**
     * Crée et insère l'enregistrement parent partagé par les tests du sélecteur et du contrôleur.
     * L'annotation réservée aux tests signifie que cette classe n'entre pas dans la couverture en production.
     **/
    public static Account createTestAccount() {
        // Construire le sObject en mémoire, l'insérer dans la transaction de test et renvoyer l'ID généré.
        Account acc = new Account(Name='Test Account');
        insert acc;
        return acc;
    }

    /**
     * Crée et insère une Opportunity liée à l'Account fourni.
     * Cette méthode est utilisée par les tests du LWC Opportunities associé.
     **/
    public static Opportunity createTestOpportunity(Id accountId) {
        // Renseigner les champs requis d'Opportunity et relier l'enregistrement à l'Account parent.
        Opportunity opp = new Opportunity(
            Name='Test Opportunity',
            StageName='Prospecting',
            CloseDate=System.today().addDays(30),
            Amount=10000,
            AccountId=accountId
        );
        insert opp;
        return opp;
    }

    /**
     * Crée et insère un Case dont le Subject contient le mot-clé recherché par les tests.
     * La méthode renvoie l'enregistrement inséré afin qu'un test puisse consulter son ID généré.
     **/
    public static Case createTestCase(Id accountId) {
        // Utiliser un Subject prévisible afin que les tests du sélecteur puissent rechercher « Generator ».
        Case c = new Case(
            AccountId = accountId,
            Subject = 'Test Generator Breakdown',
            Status = 'New',
            Priority = 'High'
        );
        insert c;
        return c;
    }
}
