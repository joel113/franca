/*
 * generated by Xtext
 */
package org.franca.deploymodel.dsl.ui.contentassist

import com.google.common.collect.Lists
import com.google.common.collect.Sets
import com.google.inject.Inject
import java.util.Collection
import java.util.Iterator
import java.util.List
import java.util.Set
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.jdt.internal.core.JavaProject
import org.eclipse.xtext.Assignment
import org.eclipse.xtext.GrammarUtil
import org.eclipse.xtext.Keyword
import org.eclipse.xtext.RuleCall
import org.eclipse.xtext.resource.IContainer
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.resource.IResourceDescription
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.ui.editor.contentassist.ContentAssistContext
import org.eclipse.xtext.ui.editor.contentassist.ICompletionProposalAcceptor
import org.franca.core.franca.FEnumerationType
import org.franca.core.franca.FStructType
import org.franca.core.franca.FType
import org.franca.core.franca.FTypeCollection
import org.franca.core.franca.FUnionType
import org.franca.core.utils.FrancaIDLUtils
import org.franca.deploymodel.core.FDModelUtils
import org.franca.deploymodel.dsl.fDeploy.FDAbstractExtensionElement
import org.franca.deploymodel.dsl.fDeploy.FDBuiltInPropertyHost
import org.franca.deploymodel.dsl.fDeploy.FDModel
import org.franca.deploymodel.dsl.fDeploy.FDOverwriteElement
import org.franca.deploymodel.dsl.fDeploy.FDeployPackage
import org.franca.deploymodel.dsl.fDeploy.Import
import org.franca.deploymodel.dsl.scoping.DeploySpecProvider
import org.franca.deploymodel.dsl.scoping.DeploySpecProvider.DeploySpecEntry
import org.franca.deploymodel.extensions.ExtensionRegistry
import org.franca.deploymodel.extensions.IFDeployExtension
import org.franca.deploymodel.extensions.IFDeployExtension.ElementDef
import org.franca.deploymodel.extensions.IFDeployExtension.RootDef
import org.franca.deploymodel.extensions.IFDeployExtension.TypeDef

/** 
 * see
 * http://www.eclipse.org/Xtext/documentation/latest/xtext.html#contentAssist on
 * how to customize content assistant
 * 
 * TODO: convert this to real Xtend (has been converted automatically from bad Java code)
 */
class FDeployProposalProvider extends AbstractFDeployProposalProvider {
	@Inject package DeploySpecProvider deploySpecProvider
	@Inject package ContainerUtil containerUtil

	val static extensionsForImportURIScope = #["fidl", "fdepl"]

	/** 
	 * Avoid generic proposal "importURI". 
	 */
	override void complete_STRING(EObject model, RuleCall ruleCall, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		var Assignment ass = GrammarUtil::containingAssignment(ruleCall)
		if (ass === null || !"importURI".equals(ass.feature)) {
			super.complete_STRING(model, ruleCall, context, acceptor)
		}
	}

	override void completeFDTypes_Target(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		var IScope scope = this.getScopeProvider().getScope(model, FDeployPackage.Literals::FD_TYPES__TARGET)
		for (IEObjectDescription description : scope.getAllElements()) {
			// only FTypeCollection instances will be in the scope
			var FTypeCollection collection = (description.getEObjectOrProxy() as FTypeCollection)
			var String qualifiedName = description.getQualifiedName().toString()
			var String uri = collection.eResource().getURI().toString()
			if (collection.name === null || collection.name.isEmpty()) {
				acceptor.accept(
					this.createCompletionProposal(qualifiedName, '''�qualifiedName� (anonymous) - �uri�'''.toString,
						null, context))
			} else {
				acceptor.accept(
					this.createCompletionProposal(qualifiedName, '''�qualifiedName� - �uri�'''.toString, null, context))
			}
		}
	}

	/** 
	 * Proposes both all fidl and fdepl files in the current workspace (to be
	 * precise: the files residing in visible containers) as well as the
	 * fdepl-files contributed by means of
	 * <code> &lt;extension point="org.franca.deploymodel.dsl.deploySpecProvider"> </code>
	 */
	override void completeImport_ImportURI(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		val List<IContainer> visibleContainers = containerUtil.getVisibleContainers(model.eResource)
		val URI fromURI = model.eResource.URI
		val List<URI> proposedURIs = newArrayList
		var FDModel fdmodel = null
		if (model instanceof FDModel) {
			fdmodel = model
		} else if (model instanceof Import) {
			fdmodel = model.eContainer as FDModel
		}
		var EList<Import> imports = fdmodel.getImports()
		var List<String> importedUris = Lists::newArrayList()
		for (Import import1 : imports) {
			importedUris.add(import1.getImportURI())
		}
		for (IContainer iContainer : visibleContainers) {
			var Iterable<IResourceDescription> resourceDescriptions = iContainer.getResourceDescriptions()
			for (var Iterator<IResourceDescription> iterator = resourceDescriptions.iterator(); iterator.hasNext();) {
				var IResourceDescription desc = iterator.next()
				var URI uri = desc.getURI()
				if (!uri.equals(fromURI) && extensionsForImportURIScope.contains(uri.fileExtension)) {
					proposedURIs.add(desc.getURI())
				}
			}
		}
		for (URI uri : proposedURIs) {
			var String result = FrancaIDLUtils::relativeURIString(fromURI, uri)
			if (!importedUris.contains(result)) {
				var String displayString = '''�uri.lastSegment()� - �result�'''.toString
				acceptor.accept(createCompletionProposal('''"�result�"'''.toString, displayString, null, context))
			}
		}

		val List<URI> classpathResources = newArrayList
		val resourceSet = model.eResource.resourceSet as XtextResourceSet
		val Object classpathURIContext = resourceSet.getClasspathURIContext()
		if (classpathURIContext instanceof JavaProject) {
			for (IContainer iContainer : visibleContainers) {
				var Iterable<IResourceDescription> resourceDescriptions = iContainer.getResourceDescriptions()
				for (IResourceDescription rd : resourceDescriptions) {
					val uri = rd.URI
					val uriModel = model.eResource.URI.toString
					if (uri.toString !== uriModel && extensionsForImportURIScope.contains(uri.fileExtension)) {
						classpathResources.add(uri)
					}
				}
			}
		}

		// TODO: why is this conditional if both pathes execute the same function call?		
//		if (context.getPrefix() === "\"classpath:") {
//			createProposals(context, acceptor, classpathResources, fromURI, importedUris)
//		} else {
//			createProposals(context, acceptor, classpathResources, fromURI, importedUris)
//		}
		createProposals(context, acceptor, classpathResources, fromURI, importedUris)

		super.completeImport_ImportURI(model, assignment, context, acceptor)
	}

	def private void createProposals(ContentAssistContext context, ICompletionProposalAcceptor acceptor,
		List<URI> classpathResources, URI fromURI, List<String> importedUris) {
		for (path : classpathResources) {
			val classpathString = path.toClassPathString 
			if (! importedUris.contains(classpathString)) {
				val result = '''"�classpathString�"'''
				val displayString = '''�path.lastSegment� - �classpathString�'''.toString
				acceptor.accept(
					createCompletionProposal(result, displayString, null, context))
			}
		}
	}

	override void completeImport_ImportedSpec(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		var Collection<DeploySpecEntry> entries = deploySpecProvider.getEntries()
		for(dse : entries) {
			acceptor.accept(
				createCompletionProposal(dse.alias, '''�dse.alias� - �dse.resourceId�'''.toString, null, context))
		}
	}

	def private String toClassPathString(URI uri) {
		val segments = classPathSegments(uri.segmentsList)
		'''classpath:/�segments.join("/")�'''
	}

	def private List<String> classPathSegments(List<String> list) {
		list.subList(3, list.size)
	}

	/** 
	 * A set of keywords which will be filtered from the proposals list.
	 */
	Set<String> filteredKeywords = Sets::newHashSet()

	override void completeKeyword(Keyword keyword, ContentAssistContext contentAssistContext,
		ICompletionProposalAcceptor acceptor) {
		if (filteredKeywords.contains(keyword.getValue()))
			return;

		// don't show "as" keyword for extension elements if they must not have a name
		if (keyword.value=="as") {
			val obj = contentAssistContext.previousModel
			if (obj instanceof FDAbstractExtensionElement) {
				val elementDef = ExtensionRegistry.getElement(obj)
				if (elementDef===null || ! elementDef.mayHaveName)
					return
			}
		}
		
		super.completeKeyword(keyword, contentAssistContext, acceptor)
	}

	override void complete_PROPERTY_HOST(EObject model, RuleCall ruleCall, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		// collect built-in property hosts
		for(FDBuiltInPropertyHost host : FDBuiltInPropertyHost.values()) {
			val proposal = host.literal
			val displayString = proposal + " (built-in)"
			acceptor.accept(createCompletionProposal(proposal, displayString, null, context));
		}
		
		// collect hosts from all registered deployment extensions
		val extensionHosts = ExtensionRegistry.hosts
		for(IFDeployExtension.Host host : extensionHosts.keySet()) {
			val proposal = host.name
			val displayString = proposal + " (" + extensionHosts.get(host).getShortDescription() + ")"
			acceptor.accept(createCompletionProposal(proposal, displayString, null, context));
		}
	}

	override void completeFDExtensionRoot_Tag(
			EObject model,
			Assignment assignment,
			ContentAssistContext context,
			ICompletionProposalAcceptor acceptor) {
		val roots = ExtensionRegistry.roots
		for(RootDef root : roots.keySet()) {
			val proposal = root.tag
			val displayString = proposal + " (" + roots.get(root).getShortDescription() + ")"
			acceptor.accept(createCompletionProposal(proposal, displayString, null, context))
		}
		completeRuleCall(assignment.getTerminal as RuleCall, context, acceptor)
	}

	override void complete_FDExtensionElement(EObject elem, RuleCall ruleCall, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		if (elem instanceof FDAbstractExtensionElement) {
			val elementDef = ExtensionRegistry.getElement(elem)
			
			// add one proposal for each child
			for(ElementDef child : elementDef.getChildren()) {
				val proposal = child.tag
				val displayString = proposal + " (from extension)"
				acceptor.accept(createCompletionProposal(proposal, displayString, null, context));
			}
		}
	}

	override void completeFDExtensionType_Name(
			EObject model,
			Assignment assignment,
			ContentAssistContext context,
			ICompletionProposalAcceptor acceptor) {
		val types = ExtensionRegistry.types
		for(TypeDef type : types.keySet()) {
			val proposal = type.name
			val displayString = proposal + " (" + types.get(type).getShortDescription() + ")"
			acceptor.accept(createCompletionProposal(proposal, displayString, null, context))
		}
		completeRuleCall(assignment.getTerminal as RuleCall, context, acceptor)
	}

	override void complete_FDTypeOverwrites(EObject elem, RuleCall ruleCall, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		var FType targetType = null
		if (elem instanceof FDOverwriteElement) {
			targetType = FDModelUtils::getOverwriteTargetType(elem)
		}
		if (targetType === null) {
			showKeywords(false, false, false, false)
		} else {
			if (targetType instanceof FEnumerationType) {
				showKeywords(true, true, false, false)
			} else if (targetType instanceof FStructType) {
				showKeywords(true, false, true, false)
			} else if (targetType instanceof FUnionType) {
				showKeywords(true, false, false, true)
			} else {
				showKeywords(true, false, false, false)
			}
		}
	}

	def private void showKeywords(boolean plain, boolean enumeration, boolean struct, boolean union) {
		val String p = "#"
		val String e = "#enumeration"
		val String s = "#struct"
		val String u = "#union"
		if(plain) filteredKeywords.remove(p) else filteredKeywords.add(p)
		if(enumeration) filteredKeywords.remove(e) else filteredKeywords.add(e)
		if(struct) filteredKeywords.remove(s) else filteredKeywords.add(s)
		if(union) filteredKeywords.remove(u) else filteredKeywords.add(u)
	}
}
