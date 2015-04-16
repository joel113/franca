package org.example.spec;

import java.util.List;
import java.util.Map;

import org.eclipse.emf.ecore.EObject;
import org.franca.core.franca.FField;
import org.franca.deploymodel.core.MappingGenericPropertyAccessor;
import org.franca.deploymodel.dsl.fDeploy.FDCompoundOverwrites;
import org.franca.deploymodel.dsl.fDeploy.FDFieldOverwrite;

import com.google.common.collect.Maps;

public class OverwriteAccessor extends AbstractSpecCompoundHostsDataPropertyAccessor {

	private final ISpecCompoundHostsDataPropertyAccessor delegate;
	
	private final Map<FField, FDFieldOverwrite> mapping;
	
	public OverwriteAccessor(
			FDCompoundOverwrites overwrites,
			ISpecCompoundHostsDataPropertyAccessor delegate,
			MappingGenericPropertyAccessor genericAccessor)
	{
		super(genericAccessor);
		this.delegate = delegate;

		// build mapping
		this.mapping = Maps.newHashMap();
		if (overwrites!=null) {
			List<FDFieldOverwrite> fields = overwrites.getFields();
			for(FDFieldOverwrite f : fields) {
				this.mapping.put(f.getTarget(), f);
			}
		}
	}
	
	@Override
	public StringProp getStringProp (EObject obj) {
		// check if this field is overwritten
		if (mapping.containsKey(obj)) {
			FDFieldOverwrite fo = mapping.get(obj);
			String e = target.getEnum(fo, "StringProp");
			if (e!=null)
				return convertStringProp(e);
		}
		return delegate.getStringProp(obj);
	}

	@Override
	public Integer getArrayProp (EObject obj) {
		if (mapping.containsKey(obj)) {
			FDFieldOverwrite fo = mapping.get(obj);
			Integer v = target.getInteger(fo, "ArrayProp");
			if (v!=null)
				return v;
		}
		return delegate.getArrayProp(obj);
	}
	
	@Override
	public Integer getSFieldProp (FField obj) {
		// check if this field is overwritten
		if (mapping.containsKey(obj)) {
			FDFieldOverwrite fo = mapping.get(obj);
			Integer v = target.getInteger(fo, "SFieldProp");
			if (v!=null)
				return v;
		}
		return delegate.getSFieldProp(obj);
	}
 
	@Override
	public Integer getUFieldProp (FField obj) {
		// check if this field is overwritten
		if (mapping.containsKey(obj)) {
			FDFieldOverwrite fo = mapping.get(obj);
			Integer v = target.getInteger(fo, "UFieldProp");
			if (v!=null)
				return v;
		}
		return delegate.getUFieldProp(obj);
	}
 
	@Override
	public ISpecCompoundHostsDataPropertyAccessor getOverwriteAccessor (FField obj) {
		// check if this field is overwritten
		if (mapping.containsKey(obj)) {
			FDFieldOverwrite fo = mapping.get(obj);
			FDCompoundOverwrites overwrites = fo.getOverwrites();
			if (overwrites==null)
				return this; // TODO: correct?
			else
				// TODO: this or delegate?
				return new OverwriteAccessor(overwrites, this, target);
			
		}
		return delegate.getOverwriteAccessor(obj);
	}

}
